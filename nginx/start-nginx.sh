#!/bin/sh

set -eu

: "${DOMAIN:=traffic.muneersahel.com}"

LIVE_DIR="/etc/letsencrypt/live/${DOMAIN}"
CURRENT_DIR="/etc/nginx/certs/current"
SELFSIGNED_DIR="/etc/nginx/certs/selfsigned"

mkdir -p "$CURRENT_DIR" "$SELFSIGNED_DIR" "/var/www/certbot"

link_current_cert() {
  ln -sf "$1/fullchain.pem" "$CURRENT_DIR/fullchain.pem"
  ln -sf "$1/privkey.pem" "$CURRENT_DIR/privkey.pem"
}

if [ -f "$LIVE_DIR/fullchain.pem" ] && [ -f "$LIVE_DIR/privkey.pem" ]; then
  echo "Using existing Let's Encrypt certificate for ${DOMAIN}"
  link_current_cert "$LIVE_DIR"
else
  if [ ! -f "$SELFSIGNED_DIR/fullchain.pem" ] || [ ! -f "$SELFSIGNED_DIR/privkey.pem" ]; then
    echo "Generating temporary self-signed certificate for ${DOMAIN}"
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
      -keyout "$SELFSIGNED_DIR/privkey.pem" \
      -out "$SELFSIGNED_DIR/fullchain.pem" \
      -subj "/CN=${DOMAIN}"
  fi
  link_current_cert "$SELFSIGNED_DIR"
fi

exec nginx -g 'daemon off;'
