#!/bin/sh

set -eu

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_DIR/.env.production}"
ACTION="${1:-up}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

cd "$PROJECT_DIR"

case "$ACTION" in
  up)
    docker compose up -d --build
    ;;
  down)
    docker compose down
    ;;
  restart)
    docker compose up -d --build --force-recreate
    ;;
  logs)
    shift || true
    docker compose logs -f "$@"
    ;;
  ps)
    docker compose ps
    ;;
  pull)
    docker compose pull
    ;;
  build)
    docker compose build
    ;;
  *)
    echo "Usage: ./run-service.sh {up|down|restart|logs|ps|pull|build}"
    exit 1
    ;;
esac
