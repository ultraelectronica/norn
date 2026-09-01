# Norn — Docs

Norn is a personal/multi-user AI chat client in the spirit of ChatGPT
and Claude, with first-class **multi-model support**, **BYOK** (bring your own
key), and **offline/self-hosted** model support. OpenRouter's free models ship
as the default; everything else is opt-in per user.

> **Status:** Planning. Architecture and tech stack are locked; implementation
> has not started.

## Why "Norn"

*Norn* comes from the Norse Norns (Urðr, Verðandi, Skuld) — weavers of fate who
govern past, present, and future. The metaphor fits an AI that holds all three
in one mind: memory, context, and prediction. Precise, calm, intelligent,
trustworthy, slightly mechanical — a machine whose mind is time.

The visual direction is a **right-facing cyborg profile whose cranium is a
clock** — half-organic, half-mechanical, with a subtle panel seam and
minimalist clock hands at 10 and 2.

## Brand

The logo is the cyborg/clock mark — premium, sparse, cinematic.

- **Palette:** gunmetal `#3A3D44` → white gradient, off-white `#ECEDEE`, charcoal `#2A2C31`
- **Background:** transparent
- **Format:** SVG + 1024px PNG, square safe-area that crops to a circle for app icons
- **Generation:** rendered via the `brandkit` skill, output lands in `assets/logo/`

Concept boards are produced after the plan is approved; see [PLAN.md](./PLAN.md).

## Documentation index

| Doc | Contents |
|---|---|
| [PLAN.md](./PLAN.md) | Vision, confirmed decisions, in/out of scope, phased roadmap, open risks |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System diagram, AWS components, backend/frontend layers, data flow, streaming decision, security |
| [TECH_STACK.md](./TECH_STACK.md) | Every technology choice with rationale — AWS, Go libs, Flutter packages, dev tooling |
| [DATA_MODEL.md](./DATA_MODEL.md) | PostgreSQL schema, table responsibilities, relationships, encryption & indexing notes |

## Quick facts

| | |
|---|---|
| **Client** | Flutter, Android only |
| **Backend** | Go, monolith, N-layer |
| **Datastore** | PostgreSQL (RDS) |
| **Cloud** | AWS — ECS Fargate, Lambda, RDS, S3, ElastiCache, Cognito, ALB, API Gateway |
| **Default models** | OpenRouter free tier |
| **Extensibility** | BYOK providers + offline models via OpenAI-compatible adapter |
| **Principles** | KISS · DRY · SOLID · YAGNI |
| **IaC** | Terraform |

## Repository layout (target)

```
norn/
├── app/            # Flutter application (existing scaffold relocates here)
├── backend/        # Go monolith
├── infra/          # Terraform
├── docs/           # this documentation
├── scripts/        # dev/release helpers
├── assets/logo/    # brandkit output
└── graphify-out/   # codebase knowledge graph (dev-time, regenerated)
```
