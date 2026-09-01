# Norn — Phasing

Executable build sequence for `norn`. Each phase is a **vertical slice** that
ends shippable. No phase starts until its exit criteria are demoed on a real
device + deployed infra (where infra exists).

Principles: **KISS · DRY · SOLID · YAGNI** — no layer/file is created until its
first consumer exists. Dependencies point inward; new providers are new adapters
(Open-Closed).

Status: **Planning → Phase 0 not yet started.** See [PLAN.md](./PLAN.md) for
vision/scope and [ARCHITECTURE.md](./ARCHITECTURE.md) for system topology.

---

## Overview

| Phase | Name | Goal | Depends on | Est. |
|---|---|---|---|---|
| **0** | **Foundations** | Repo, CI and skeleton deploy | — | 2–3 d |
| **1** | **Auth** | Cognito OIDC, JWT, login works | 0 | 3–5 d |
| **2** | **Chat MVP** | OpenRouter free models + SSE + persistence | 1 | 5–7 d |
| **3** | **BYOK** | User-owned keys, KMS envelope, OpenAI-compat adapter | 2 | 3–4 d |
| **4** | **Offline** | Ollama/vLLM via same adapter, local picker | 3 | 2–3 d |
| **5** | **Scale** | Redis cache, rate-limit, Lambda async jobs | 2 | 3–4 d |
| **6** | **Polish** | Brand, observability, hardening, graphify | 5 | 3–4 d |
| **7** | **Next** | RAG / billing / multi-client — **deferred** | 6 | — |

```
0 Foundations ─┬─► 1 Auth ──► 2 Chat MVP ──► 3 BYOK ──► 4 Offline ──┐
               │                              │                    │
               │                              └─► 5 Scale ─────────┴─► 6 Polish ──► 7 Next
               └─► infra baseline already done ──────────────────────┘
```

Phases 3 and 5 can overlap after Phase 2 is green; Phase 4 requires 3.
Phase 5 is deliberately after 2 so rate-limit/metering has a real traffic
shape to measure. If team size = 1, run strictly sequential 0→6.

Global Definition of Done (every phase):
- `docker compose up -d` green locally; `go test ./...` + `dart analyze` pass
- `terraform plan` clean (no drift) for any infra touched
- CI (lint, test, build → ECR) green on `main`
- No secrets in repo; no plaintext BYOK logs; every user-scoped query filters `user_id`

---

## Phase 0 — Foundations

**Objective:** Empty app builds, empty backend serves, infra provisions, CI proves it.

Why first: without a deployable skeleton every later phase pays integration tax.

### Scope

| Area | Tasks |
|---|---|
| **Backend** | `cmd/server/main.go` composition root · `/healthz` + `/readyz` · `internal/config` env parsing (`caarlos0/env` or stdlib) · `internal/provider` `ChatProvider` interface only · `Dockerfile` multi-stage (golang:1.22 → distroless) · `golang-migrate` `000001_init` migration (schema from [DATA_MODEL.md](./DATA_MODEL.md) + provider seed) |
| **Infra** | `infra/` modules: `network` (VPC), `data` (RDS Postgres 16, ElastiCache Redis 7 — created but not yet wired), `compute` (ECS Fargate cluster + ECR repo + ALB stub), `state` (S3 backend + DynamoDB lock) · `variables.tf` / `providers.tf` already exist — add `outputs.tf`, `main.tf` wiring · `terraform fmt` + `validate` |
| **App** | Move existing Flutter scaffold into `app/` (already done) · `analysis_options.yaml` + `flutter_lints` · add deps: `dio`, `flutter_riverpod`, `drift`, `flutter_secure_storage`, `freezed`, `json_serializable`, `go_router`, `flutter_markdown` · placeholder `lib/main.dart` that renders health check |
| **DevOps** | GitHub Actions: `ci.yml` (go vet/lint, `go test`, `dart analyze`, `terraform plan`, docker build push to ECR on `main`) · `compose.yaml` pg+redis already exists · `.env.example` completed · `scripts/dev.sh` (migrate up + run server) |

Out of scope: Cognito, ALB OIDC, any chat logic, Redis client wiring, KMS.

Exit criteria:
- [ ] `terraform init && terraform plan` passes with 0 errors on a fresh AWS account
- [ ] `docker build backend/` succeeds; `/healthz` returns 200 on Fargate stub
- [ ] `flutter run` launches on Android emulator, shows health status
- [ ] CI green on empty build

Risks: Terraform state bootstrap chicken-and-egg → solve with manual `aws s3api create-bucket` one-time bootstrap script checked into `scripts/bootstrap-state.sh`.

---

## Phase 1 — Auth

**Objective:** A real user can sign in on device and hit an authenticated backend.

Decision to make in this phase: **IdP pick — Google vs GitHub** (single OAuth provider via Cognito federation). Default recommendation: **Google** (larger user base, better mobile UX). Lock before infra apply.

### Scope

| Area | Tasks |
|---|---|
| **Infra** | `infra/modules/auth`: Cognito User Pool + App Client + Domain + Federated IdP (OIDC) · ALB listener rule with `authenticate-oidc` action for `/api/*` · Secrets Manager entries for OAuth client secret · Route53 + ACM cert for ALB · WAF stub |
| **Backend** | `internal/auth`: JWT validation middleware (ALB already validates; backend re-validates `sub` claim) · `cognito_sub → users.id` resolver (lazy user creation on first valid JWT) · `internal/transport/middleware/auth.go` · `internal/repository` sqlc queries for `users` (`GetByCognitoSub`, `CreateUser`) |
| **App** | `lib/presentation/auth`: Login screen + OAuth flow (system browser / `flutter_appauth` or Cognito Hosted UI) · `lib/data/auth`: token storage in `flutter_secure_storage`, `dio` auth interceptor, refresh logic · `lib/application/auth_provider.dart` (Riverpod) · `go_router` redirect guard (unauth → /login) |

Exit criteria:
- [ ] User taps Sign In → Hosted UI → returns to app with JWT stored securely
- [ ] `GET /api/me` returns `{ user_id, email }` for valid JWT, 401 otherwise
- [ ] ALB OIDC rejects unauthenticated `/api/*` before traffic hits Fargate (verified via curl)
- [ ] New Cognito user auto-creates `users` row on first request

Risks: ALB `authenticate-oidc` session cookie vs mobile JWT — mobile will send `Authorization: Bearer` header; ALB path for SSE vs API Gateway split must be tested early. Mitigation: test both header and cookie flows in staging.

---

## Phase 2 — Chat MVP

**Objective:** End-to-end streamed chat on OpenRouter free models, persisted across sessions. This is the product.

Largest phase; keep slices small inside it (2a models, 2b stream, 2c persistence).

### Scope

| Area | Tasks |
|---|---|
| **Backend** | `internal/provider/openrouter.go`: `OpenRouterAdapter` implementing `ChatProvider` (`Models`, `Stream`) · `internal/service/chat.go` + `conversation.go` · `internal/transport/handlers/chat.go`: `POST /api/chat` (non-stream JSON) + `POST /api/chat/stream` (SSE) · `internal/transport/sse.go`: `Content-Type: text/event-stream` writer, flush, context cancellation · `internal/repository` sqlc for `conversations`, `messages`, `models_cache`, `providers` · `go.mod` deps: `pgx`, `sqlc`, `redis/go-redis` (stub), `aws-sdk-go-v2` |
| **Infra** | Wire RDS + ElastiCache into Fargate task definition (env via Secrets Manager) · ALB target group health check on `/healthz` · CloudFront → ALB for `/api/chat/stream` (cache disabled, SSE passthrough) · API Gateway not yet needed |
| **App** | `lib/domain/entities`: `Conversation`, `Message`, `Model` (freezed) · `lib/data/chat`: `dio` SSE client (`ResponseType.stream`), line-delimited `data:` parser, cancellation via `CancelToken` · `lib/data/local`: `drift` DB for offline conversation/message cache · `lib/application/chat_provider.dart` + `conversation_provider.dart` · `lib/presentation/chat`: conversation list, chat thread (markdown + code highlight), model picker (free models only), streaming indicator + stop button |

Sequence inside Phase 2:
1. **2a — Models:** `GET /api/models?filter=free` returns OpenRouter free catalog (cached in-memory first, Redis later)
2. **2b — Streaming:** `POST /api/chat/stream` proxies tokens to SSE; app renders token-by-token
3. **2c — Persistence:** on stream completion, persist `messages` (user + assistant) + bump `conversations.updated_at`; conversation list loads from Postgres (drift mirror for offline read)

Exit criteria:
- [ ] User picks a `:free` model, sends a message, sees tokens stream in <1s TTFB
- [ ] Kill app + reopen → conversation history is intact (Postgres + drift)
- [ ] Client disconnect mid-stream cancels upstream provider call (no orphan spend)
- [ ] `GET /api/conversations` is scoped by `user_id` (cross-user read returns 0 rows)

Risks: OpenRouter rate limits on free tier; SSE buffering by intermediaries. Mitigations: CloudFront cache behavior `CachePolicy: CachingDisabled`, ALB idle timeout 120s, provider timeout + retry with backoff.

---

## Phase 3 — BYOK

**Objective:** User adds their own provider API key and chats with a paid or third-party model.

Keystone insight from [ARCHITECTURE.md](./ARCHITECTURE.md): BYOK + offline share one adapter (`OpenAICompatAdapter`), so this phase builds the adapter that Phase 4 reuses.

### Scope

| Area | Tasks |
|---|---|
| **Backend** | `internal/crypto`: KMS envelope encrypt/decrypt (data key per user, `GenerateDataKey` + `Decrypt`) · `internal/service/keys.go` + `internal/repository` for `user_provider_keys` (ciphertext only) · `internal/provider/openai_compat.go`: `OpenAICompatAdapter` (configurable `base_url`, key injection from decrypted BYOK) · Provider resolver: if user has key for `provider_id`, use `OpenAICompatAdapter` with that key; else fall back to OpenRouter |
| **Infra** | KMS key (alias `norn/byok`) + key policy (Fargate task role can `GenerateDataKey`/`Decrypt`) · Secrets Manager rotation not needed (keys are per-user in RDS, not infra secrets) |
| **App** | `lib/presentation/settings`: Provider settings screen (list providers, add/edit/delete key, label) · `flutter_secure_storage` not used for BYOK keys (server-side KMS only; app sends plaintext once over TLS, never stores) · Model picker now shows BYOK models when key exists · Error states for invalid key (401 from provider → user-facing message) |

Exit criteria:
- [ ] User adds OpenAI key in settings → key stored as ciphertext in `user_provider_keys` (verified via `SELECT` — no plaintext)
- [ ] User selects `gpt-4o-mini` (via BYOK) → chat streams via `OpenAICompatAdapter`
- [ ] Deleting a key immediately makes that provider unavailable (no cached plaintext)
- [ ] Plaintext key never appears in CloudWatch logs

Risks: KMS throttling under burst. Mitigation: cache decrypted key in-process for request lifetime only, never persist.

---

## Phase 4 — Offline

**Objective:** User self-hosts Ollama/vLLM and chats with a local model through the same interface.

This phase is intentionally small — it is a configuration + UX layer on top of Phase 3's adapter.

### Scope

| Area | Tasks |
|---|---|
| **Backend** | Extend `providers` seed with `ollama` row (`kind=openai_compat`, `base_url` user-configurable) · `OpenAICompatAdapter` already handles it — no new Go code except validation that `base_url` is user-supplied for `ollama` kind · Optional: `GET /api/providers/ollama/models` proxy to local `/v1/models` for discovery |
| **App** | Settings → Offline section: base URL input (e.g. `http://192.168.1.10:11434/v1`), test-connection button, model list fetch · Local model picker grouping (Cloud vs Offline) · Streaming UX hardening: offline models may be slow — show spinner + elapsed time + cancel affordance (from PLAN.md risk) |
| **Infra** | None (user hosts Ollama). Document `scripts/ollama-setup.md` for local dev testing |

Exit criteria:
- [ ] User sets Ollama URL + picks `llama3.1` → chat streams from local server
- [ ] Offline model failure (server down) surfaces as retryable error, does not crash app
- [ ] No infra change required; BYOK and offline paths are provably the same adapter

Risks: User LAN latency / firewall. Mitigation: in-app connection diagnostics (ping `/v1/models` with timeout + helpful error).

---

## Phase 5 — Scale

**Objective:** Shared-state caching, abuse protection, and async bookkeeping.

Can start after Phase 2; no dependency on BYOK except that rate-limit must cover BYOK paths too.

### Scope

| Area | Tasks |
|---|---|
| **Backend** | `internal/cache`: `go-redis/v9` client, model-list cache, identical-prompt cache (TTL 5m), rate-limit counters · `internal/service/ratelimit.go`: Redis token bucket per `user_id` (e.g. 30 req/min, burst 10) checked before `provider.Stream` opens · `internal/transport/middleware/ratelimit.go` |
| **Infra** | ElastiCache Redis fully wired (already provisioned in Phase 0, now used) · WAF rate-based rule (edge pre-filter) · Lambda + EventBridge: `usage-meter` (consumes EventBridge events from Fargate, upserts `usage` table), `model-sync` (cron every 6h: fetch OpenRouter `/models`, upsert `models_cache` + warm Redis) · API Gateway (HTTP API) → Lambda for non-streaming triggers · S3 bucket for exports/backups (already exists) |
| **App** | Rate-limit UI: 429 → friendly message + retry-after countdown · Usage screen: `GET /api/usage` (today/week) from `usage` table |

Exit criteria:
- [ ] 31st request in a minute returns 429 with `Retry-After` header; counter resets after window
- [ ] `usage` table increments after each chat (verified via Lambda logs, not inline write)
- [ ] `GET /api/models` serves from Redis (Fargate restart does not cold-miss)
- [ ] Model list auto-refreshes within 6h of OpenRouter catalog change

Risks: Redis as single point of failure. Mitigation: degrade gracefully — if Redis down, bypass cache and skip rate-limit (log warning, don't block chat).

---

## Phase 6 — Polish

**Objective:** Ship-quality hardening, brand, and operability.

### Scope

| Area | Tasks |
|---|---|
| **Backend** | Structured logging (`log/slog`) + X-Ray tracing · `internal/transport/middleware/logging.go`, `tracing.go` · Secrets rotation docs · `golangci-lint` strict profile · Load test (k6 or vegeta) for SSE concurrency |
| **Infra** | CloudWatch dashboards + alarms (p50/p99 latency, 5xx rate, Fargate CPU/mem, RDS connections, Redis evictions) · X-Ray sampling rules · WAF managed rules + ALB access logs → S3 · Terraform `prod` workspace + `staging` |
| **App** | `assets/logo/` via `brandkit` skill (cyborg/clock mark, gunmetal palette, SVG+1024 PNG, circular safe-area) · App icon + splash · `drift` migration polish · `flutter_markdown` code-block highlighting theme · Empty states, error states, offline banner |
| **Dev** | `graphify` wired: `graphify-out/` generation on `main` push (Lambda or GH Action) · `docs/` final pass · Security review: OWASP MASVS checklist, dependency audit (`govulncheck`, `flutter pub audit`) |

Exit criteria:
- [ ] CloudWatch dashboard shows p99 stream TTFB, error rate, and per-user usage
- [ ] Logo renders correctly as app icon (circular crop), splash, and README header
- [ ] `graphify-out/` regenerates on demand and is linked from docs
- [ ] Security review passes: no hardcoded secrets, TLS pinned, KMS envelope verified

---

## Phase 7 — Next (deferred)

Not scheduled. Candidates when Phases 0–6 are stable:

| Candidate | Notes |
|---|---|
| **RAG over `graphify-out/`** | Codebase Q&A chatbot; separate vector store, not in primary data model |
| **Payments / billing** | Stripe integration; `usage` table already meters — add checkout + entitlements |
| **Multi-provider OAuth** | Cognito federation to second IdP (GitHub if Phase 1 picked Google) |
| **Web / iOS / desktop** | Flutter multi-target; responsive layout deferred per PLAN.md |
| **WebSocket API** | Only if realtime beyond SSE is needed (collaborative features) |

Each candidate becomes its own phased slice when prioritized — no work starts until a one-page RFC is approved.

---

## Running order for a solo builder

If one person builds end-to-end, follow this exact ticket order and do not
parallelize until Phase 2 is demoed:

1. Phase 0 — one PR: `infra: bootstrap` + `backend: health` + `app: deps`
2. Phase 1 — one PR per layer: `infra(auth)` → `backend(auth)` → `app(auth)`
3. Phase 2 — three PRs: `models` → `stream` → `persistence`
4. Phase 3 — two PRs: `crypto+kms` → `byok ui`
5. Phase 4 — one PR: `offline` (mostly app + docs)
6. Phase 5 — two PRs: `redis+ratelimit` → `lambda+metering`
7. Phase 6 — two PRs: `observability` → `brand+polish`

Keep PRs <400 lines; each PR must keep `main` deployable.

---

## Change log

| Date | Change |
|---|---|
| 2026-08-27 | Initial phasing extracted from PLAN.md roadmap (0–6) and expanded to executable tasks. |
