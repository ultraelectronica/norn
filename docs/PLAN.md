# Plan

## Vision

A multi-user AI chat application that gives each user one consistent chat
experience across many model providers, with sensible free defaults and the
escape hatch of self-hosted offline models. Not a thin wrapper — a real product
with auth, persistence, streaming, metering, and operability baked in.

## Goals

1. **Multi-provider chat** through a single interface, defaulting to OpenRouter's
   free models so it works on day one with no setup.
2. **BYOK** — users add their own provider API keys; keys are encrypted at rest.
3. **Offline / self-hosted** models via OpenAI-compatible servers (Ollama, vLLM).
4. **Multi-user from day one** — proper auth, per-user isolation, per-user
   rate limiting and usage metering.
5. **Operable** — infrastructure as code, CI, observability, backups.

## Non-goals (for now)

- iOS / web / desktop clients (Android first).
- A custom model gateway / fine-tuning.
- Realtime collaboration or shared conversations.
- Payments / billing integration (usage is metered, not charged).
- A WebSocket protocol beyond SSE streaming.
- Custom auth provider federation beyond the single chosen IdP.

## Confirmed decisions

| Decision | Choice | Implication |
|---|---|---|
| User model | **Multi-user from day 1** | Full auth, per-user isolation, rate limit, metering; enterprise infra is justified |
| Client platforms | **Android only** | One Flutter target; responsive layout / multi-platform work deferred |
| Graphify use | **Codebase knowledge graph** | Dev-time navigation aid, not a runtime feature; regenerates `graphify-out/` |
| Logo timing | **Plan first, generate later** | Brandkit renders after docs are agreed |
| Auth | **OAuth2 single provider** via Cognito federation | One IdP (Google or GitHub), JWT sessions, no bespoke token code |
| Hosting | **ECS Fargate + RDS + Lambda + S3** | Container backend on Fargate, async jobs on Lambda, object storage on S3 |
| Streaming path | **ALB (native OIDC) → Fargate** for chat SSE; **API Gateway** only for async/Lambda endpoints | API Gateway cannot stream SSE; see ARCHITECTURE.md |

## In scope — MVP

- Cognito auth (single OAuth provider), JWT sessions
- OpenRouter free models as default
- SSE token streaming chat
- Conversation + message persistence (Postgres)
- Riverpod state, drift offline cache, flutter_secure_storage for secrets (Flutter)
- BYOK provider keys, KMS-encrypted at rest
- Offline models via the same OpenAI-compatible adapter
- Redis cache (model lists, identical-prompt cache, rate-limit counters)
- Per-user rate limiting (Redis token bucket) + edge throttle (WAF/ALB)
- Lambda async jobs: usage metering, OpenRouter model-list sync
- Terraform for all infra
- CI (lint, test, terraform plan, docker build → ECR)

## Out of scope — MVP

- Multi-provider OAuth federation
- Payments/billing
- Web/iOS/desktop clients
- Codebase-Q&A RAG over `graphify-out/` (possible Phase 7)

## Phased roadmap

> Full executable breakdown in [PHASING.md](./PHASING.md) — tasks per layer, demo scripts, and running order. Summary below.

| Phase | Outcome | Exit criteria |
|---|---|---|
| **0 — Foundations** | Repo restructure (Flutter → `app/`), Go + Terraform skeletons, Dockerfile, CI | `terraform plan` clean; CI green on empty build |
| **1 — Auth** | Cognito user pool federated to IdP, JWT flow, Flutter login screen | User can sign in, JWT validated at ALB |
| **2 — Chat MVP** | OpenRouter free models, SSE streaming, conversation persistence | End-to-end streamed chat persisted across sessions |
| **3 — BYOK** | Provider settings UI, KMS-encrypted key store, `OpenAICompatAdapter` | User adds a key and chats with a paid/offline model |
| **4 — Offline** | Ollama integration via OpenAI-compat adapter; local model picker | User chats with a self-hosted model |
| **5 — Scale bits** | Redis cache, per-user rate limit, Lambda metering + model sync | Rate limit blocks overuse; usage visible; model list auto-refreshes |
| **6 — Polish** | Logo assets in, graphify wired, CloudWatch/X-Ray, hardening | Observability dashboards + security review pass |

## Open items / risks

- **IdP not yet picked** — Google vs GitHub for the single OAuth provider. Decide in Phase 1.
- **API Gateway vs streaming** — resolved in favour of ALB for chat (see ARCHITECTURE.md). Revisit only if realtime beyond chat is needed (WebSocket API).
- **Redis vs in-process cache** — Redis chosen because Fargate runs ≥2 tasks (shared state required). If we drop to 1 task, Redis can be deferred.
- **Self-hosted model latency** — offline models on user hardware may be slow; Flutter must surface streaming progress and allow cancellation.
