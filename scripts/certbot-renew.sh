#!/bin/sh

set -eu

: "${DOMAIN:=traffic.muneersahel.com}"
: "${CERTBOT_WEBROOT:=/var/www/certbot}"
: "${CERTBOT_STAGING:=0}"

PRIMARY_DOMAIN="$(printf '%s' "$DOMAIN" | cut -d',' -f1)"
CURRENT_DIR="/etc/nginx/certs/current"

if [ -z "${LETSENCRYPT_EMAIL:-}" ] || [ "${LETSENCRYPT_EMAIL}" = "change-me@example.com" ]; then
  echo "LETSENCRYPT_EMAIL must be set to a real email address in .env.production" >&2
  exit 1
fi

mkdir -p "$CERTBOT_WEBROOT" "$CURRENT_DIR"

DOMAIN_ARGS=""
OLD_IFS="$IFS"
IFS=','
for domain in $DOMAIN; do
  DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done
IFS="$OLD_IFS"

STAGING_FLAG=""
if [ "$CERTBOT_STAGING" = "1" ]; then
  STAGING_FLAG="--staging"
fi

link_current_cert() {
  if [ -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/privkey.pem" ]; then
    ln -sf "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" "$CURRENT_DIR/fullchain.pem"
    ln -sf "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/privkey.pem" "$CURRENT_DIR/privkey.pem"
    kill -HUP 1 || true
  fi
}

echo "Requesting or reusing certificate for ${DOMAIN}"
# shellcheck disable=SC2086
certbot certonly --webroot -w "$CERTBOT_WEBROOT" \
  --email "$LETSENCRYPT_EMAIL" \
  --agree-tos \
  --no-eff-email \
  --non-interactive \
  --keep-until-expiring \
  $STAGING_FLAG \
  $DOMAIN_ARGS

link_current_cert

while true; do
  sleep 12h
  echo "Checking certificate renewal status"
  certbot renew --webroot -w "$CERTBOT_WEBROOT" $STAGING_FLAG || true
  link_current_cert
done
