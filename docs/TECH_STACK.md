# Tech Stack

Every choice with a reason. Principles: **KISS · DRY · SOLID · YAGNI** — prefer
stdlib and platform-native features; add a dependency only when it earns its
place.

## At a glance

| Layer | Technology | Why |
|---|---|---|
| Client | **Flutter / Dart** (Android) | Single codebase, strong UI tooling, good streaming story |
| Backend | **Go** (monolith, N-layer) | Concurrency for streaming, single deployable, fast cold path |
| Datastore | **PostgreSQL** (RDS) | Relational, reliable, managed backups |
| Cache / rate-limit | **Redis** (ElastiCache) | Shared across ≥2 Fargate tasks; counters + response cache |
| Cloud | **AWS** | Managed Postgres, containers, serverless, IAM, KMS |
| IaC | **Terraform** | Reproducible, declarative, DRY infra |
| Container | **Docker** (on Fargate) | Standard packaging for ECS |
| CI | **GitHub Actions** | Lint, test, `terraform plan`, build → ECR |

## AWS services

| Service | Used for |
|---|---|
| Route 53 | DNS |
| CloudFront + WAF | Edge cache, abuse/rate pre-filter |
| Cognito | User pool, OAuth2 federation, JWT issuance |
| ALB | TLS, OIDC auth, health checks, SSE passthrough |
| ECS Fargate | Go backend (≥2 tasks) |
| API Gateway (HTTP API) | Non-streaming triggers to Lambda |
| Lambda + EventBridge | Async: usage metering, model-list sync, webhooks |
| RDS PostgreSQL | Primary datastore |
| ElastiCache Redis | Cache + rate-limit counters |
| KMS | Envelope encryption for BYOK keys |
| Secrets Manager | DB creds, OAuth secret, JWT signing key |
| S3 | Uploads, exports, backups, Terraform state, graphify snapshots |
| CloudWatch + X-Ray | Logs, metrics, alarms, tracing |

## Backend — Go libraries

| Concern | Library | Rationale |
|---|---|---|
| HTTP routing | `net/http` (stdlib) or `chi` | Go 1.22+ `ServeMux` does method+path routing; chi if middleware ergonomics matter |
| Postgres driver | `pgx` | Most complete Postgres driver, native types |
| Query generation | `sqlc` | Type-safe SQL → Go; parameterized by construction (DRY, injection-proof) |
| Migrations | `golang-migrate` | Simple, CLI + embeddable |
| Rate limiting | `golang.org/x/time/rate` | Token bucket; back Redis for multi-task sharing |
| Redis | `redis/go-redis/v9` | Standard client |
| Logging | `log/slog` (stdlib) | Structured logging without a dependency |
| Config | `caarlos0/env` or stdlib `os.Getenv` | Typed env parsing |
| Testing | stdlib `testing` + `testify` only if assertions earn it | Keep deps thin |
| AWS SDK | `aws-sdk-go-v2` | Modular, current |

## Frontend — Flutter packages

| Concern | Package | Rationale |
|---|---|---|
| HTTP + SSE streaming | `dio` | Streamed responses, interceptors, cancellation |
| State management | `flutter_riverpod` | Testable, compile-safe, low boilerplate |
| Local DB / offline cache | `drift` | Type-safe SQLite, reactive queries |
| Secret storage | `flutter_secure_storage` | Android Keystore-backed |
| Data classes | `freezed` + `json_serializable` | Immutable models, JSON, copy-with |
| Navigation | `go_router` | Declarative, deep-link friendly |
| Markdown | `flutter_markdown` | Render assistant output |
| Code highlighting | `flutter_highlight` | Code blocks in chat |
| DI | Riverpod itself | No separate DI container (DRY) |

## Dev tooling

| Concern | Tool |
|---|---|
| Infra provisioning | Terraform (+ `tfenv` for versioning) |
| Container build | Docker (multi-stage) |
| CI | GitHub Actions |
| Go lint | `golangci-lint` |
| Dart lint | `dart analyze` + `flutter_lints` |
| Local dev DB | Docker Compose (Postgres + Redis) |
| Secrets (local) | `.env` gitignored; AWS Secrets Manager in prod |
| Codebase navigation | `graphify` → `graphify-out/` |

## Default model source

**OpenRouter free tier** — the free models (`:free` suffix) are the zero-config
default. The model list is cached in Redis and refreshed on a schedule by a
Lambda, so users see only currently-available free models without a setup step.
