#!/bin/sh

set -eu

ROLE="${1:-web}"

log() {
  printf '%s %s\n' "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')]" "$*"
}

run_cron() {
  : "${CRON_TARGET_URL:=http://app:3000}"
  : "${CRON_INTERVAL_SECONDS:=60}"
  : "${DAILY_AGGREGATE_HOUR_UTC:=0}"
  TARGET_HOUR_UTC="$(printf '%02d' "$DAILY_AGGREGATE_HOUR_UTC")"

  LAST_AGGREGATE_DATE=""

  while true; do
    HOUR_UTC="$(date -u +%H)"
    DATE_UTC="$(date -u +%F)"

    if [ "$HOUR_UTC" = "$TARGET_HOUR_UTC" ] && [ "$LAST_AGGREGATE_DATE" != "$DATE_UTC" ]; then
      log "Triggering daily aggregation"
      curl -fsS -X POST \
        -H "x-cron-secret: ${CRON_SECRET:-}" \
        "$CRON_TARGET_URL/api/cron/aggregate" >/dev/null
      LAST_AGGREGATE_DATE="$DATE_UTC"
    fi

    log "Triggering Stripe sync"
    curl -fsS -X POST \
      -H "x-cron-secret: ${CRON_SECRET:-}" \
      "$CRON_TARGET_URL/api/cron/stripe-sync" >/dev/null

    sleep "$CRON_INTERVAL_SECONDS"
  done
}

case "$ROLE" in
  web)
    mkdir -p "$(dirname "${DATABASE_PATH:-/app/data/analytics.db}")"
    log "Starting production web service"
    exec node server.js
    ;;
  cron)
    log "Starting cron worker"
    run_cron
    ;;
  *)
    log "Unknown role: $ROLE"
    exit 1
    ;;
esac
