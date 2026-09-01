# Norn

A multi-user AI chat client with multi-model support, BYOK, and offline
(self-hosted) model support. OpenRouter's free models are the zero-config
default.

> **Name:** *Norn* — from the Norse Norns (Urðr, Verðandi, Skuld) who weave fate
> and govern past, present, and future. A machine whose mind is time — the
> cyborg whose cranium is a clock.

## Status

**Planning.** Architecture and tech stack are locked. See the docs.

## Docs

- [docs/README.md](./docs/README.md) — overview & brand
- [docs/PLAN.md](./docs/PLAN.md) — scope, decisions, roadmap
- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) — system, layers, data flow
- [docs/TECH_STACK.md](./docs/TECH_STACK.md) — every choice, with rationale
- [docs/DATA_MODEL.md](./docs/DATA_MODEL.md) — PostgreSQL schema

## Stack

Flutter (Android) · Go monolith · PostgreSQL · Redis · AWS (ECS Fargate, Lambda,
RDS, S3, Cognito, ALB, API Gateway) · Terraform.

## Layout (target)

```
norn/
├── app/          # Flutter application
├── backend/      # Go monolith
├── infra/        # Terraform
├── docs/         # this documentation
├── scripts/      # dev/release helpers
├── assets/logo/  # brandkit output
└── graphify-out/ # codebase knowledge graph (dev-time)
```
