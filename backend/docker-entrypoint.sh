#!/bin/bash
set -e

echo "🚀 Carbon Backend Starting..."

# ── Wait for PostgreSQL ────────────────────────────────────────────────────────
DB_HOST=$(echo "$DATABASE_URL" | sed -E 's|.*@([^:/]+).*|\1|')
DB_USER=$(echo "$DATABASE_URL" | sed -E 's|.*://([^:]+):.*|\1|')

echo "⏳ Waiting for PostgreSQL at ${DB_HOST}..."
MAX_RETRIES=30
RETRY=0
until pg_isready -h "$DB_HOST" -p 5432 -U "$DB_USER" > /dev/null 2>&1; do
  RETRY=$((RETRY + 1))
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "❌ PostgreSQL did not become ready in time. Exiting."
    exit 1
  fi
  echo "  PostgreSQL unavailable (attempt $RETRY/$MAX_RETRIES) — retrying in 2s..."
  sleep 2
done

echo "✅ PostgreSQL is ready!"

# ── Detect host LAN IP ────────────────────────────────────────────────────────
# Works inside Docker (reports container IP) and bare-metal (reports LAN IP)
HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
  HOST_IP="127.0.0.1"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 API Base:  http://${HOST_IP}:${PORT:-8000}/api/v1"
echo "  ❤️  Health:   http://${HOST_IP}:${PORT:-8000}/health"
echo "  📚 Docs:      http://${HOST_IP}:${PORT:-8000}/docs"
echo "  👷 Workers:   ${WORKERS:-4} uvicorn processes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Start Uvicorn ─────────────────────────────────────────────────────────────
exec uvicorn app.main:app \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-8000}" \
    --workers "${WORKERS:-4}" \
    --log-level "${LOG_LEVEL:-info}" \
    --access-log \
    --use-colors
