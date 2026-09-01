#!/usr/bin/env bash
# Local dev loop: compose deps up → migrations → API on the host.
# The Android emulator reaches the host backend via 10.0.2.2.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found" >&2; exit 1; }
command -v migrate >/dev/null 2>&1 || {
  echo "ERROR: golang-migrate not found. Install:" >&2
  echo "  go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest" >&2
  exit 1
}

echo "==> Starting postgres + redis"
docker compose up -d postgres redis

echo "==> Waiting for postgres"
for i in $(seq 1 30); do
  if docker compose exec -T postgres pg_isready -U norn -d norn >/dev/null 2>&1; then
    break
  fi
  [ "$i" = 30 ] && { echo "ERROR: postgres never became ready" >&2; exit 1; }
  sleep 1
done

# Load backend env (cp backend/.env.example backend/.env on first run).
if [ -f backend/.env ]; then
  set -a
  # shellcheck disable=SC1091
  . backend/.env
  set +a
fi
: "${DATABASE_URL:=postgres://norn:norn@localhost:5432/norn?sslmode=disable}"
export DATABASE_URL

echo "==> Applying migrations"
migrate -path backend/migrations -database "$DATABASE_URL" up

echo "==> Running API on :${HTTP_PORT:-8080}"
cd backend
exec go run ./cmd/server
