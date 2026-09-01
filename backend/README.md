# Norn backend

Go monolith, N-layer. Phase 0 skeleton: health endpoint + config + provider
contract + initial migration. See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
for the full layer plan.

## Layout

```
backend/
├── cmd/server/            # entrypoint + wiring
├── internal/
│   ├── config/            # env config
│   └── provider/          # ChatProvider interface (keystone)
│   # ─── wired in later phases ───
│   # transport/  HTTP handlers + middleware + SSE
│   # service/    use cases (chat, conversations, keys, usage)
│   # repository/ sqlc-generated Postgres access
│   # auth/       JWT validation, subject → user
│   # crypto/     KMS envelope encrypt/decrypt
│   # cache/      Redis client
├── migrations/            # golang-migrate (000001_init lays down the schema)
├── Dockerfile
└── go.mod
```

Dirs for not-yet-implemented layers are intentionally absent (YAGNI) — created
when their first file lands.

## Run locally

Go is not installed in this environment; on a dev machine:

```bash
cp .env.example .env       # fill in
go test ./...
go run ./cmd/server        # GET /healthz -> ok
```

## Migration

```bash
migrate -path migrations -database "$DATABASE_URL" up
```

Initial migration seeds the provider catalog (`openrouter`, `openai`,
`anthropic`, `ollama`).
