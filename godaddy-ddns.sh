#!/bin/sh
# GoDaddy DDNS updater — reference copy of the live script.
# Deployed via ansible/roles/godaddy_ddns/templates/godaddy-ddns.sh.j2
# to /etc/godaddy-ddns/godaddy-ddns.sh on the Pi.
# GoDaddy DDNS updater — runs inside the alpine container.
# Expects GD_DOMAIN, GD_RECORD_NAMES (comma-separated, @ = zone apex),
# and GD_SECRET in the environment.

set -eu

apk add --no-cache curl jq >/dev/null

DOMAIN="${GD_DOMAIN:?GD_DOMAIN is required}"
RECORD_NAMES="${GD_RECORD_NAMES:?GD_RECORD_NAMES is required}"
SECRET="${GD_SECRET:?GD_SECRET is required}"
API="https://api.godaddy.com/v3/domains/zones/${DOMAIN}/dns-records"

# Apex recordIds from GoDaddy can contain [] which curl treats as URL globs
# (exit 3 / URL malformed) unless globbing is off.
uri_encode() {
    jq -nr --arg s "$1" '$s | @uri'
}

fqdn_for() {
    if [ "$1" = "@" ]; then
        echo "$DOMAIN"
    else
        echo "$1.$DOMAIN"
    fi
}

godaddy_json() {
    curl -sS -g -L -w "\nHTTP_STATUS:%{http_code}" "$@" || true
}

upsert_a_record() {
    NAME="$1"
    FQDN=$(fqdn_for "$NAME")
    echo "Attempting to sync ${FQDN} (name=${NAME}) to ${IP}"

    RECORDS_JSON=$(curl -sS -g -G "$API" \
      --data-urlencode "type=A" \
      --data-urlencode "name=${NAME}" \
      -H "Authorization: Bearer ${SECRET}" || true)

    RECORD_ID=$(echo "$RECORDS_JSON" | jq -r '.items[0].recordId // empty' 2>/dev/null || true)

    if [ -n "$RECORD_ID" ]; then
        ENC_ID=$(uri_encode "$RECORD_ID")
        echo "Attempting to update existing recordId $RECORD_ID"
        HTTP_RESPONSE=$(godaddy_json \
          -X PUT "${API}/${ENC_ID}" \
          -H "Authorization: Bearer ${SECRET}" \
          -H "Content-Type: application/json" \
          -d "{ \"type\": \"A\", \"name\": \"${NAME}\", \"data\": \"${IP}\", \"ttl\": 600 }")
    else
        echo "No existing A record for ${FQDN}; creating"
        HTTP_RESPONSE=$(godaddy_json \
          -X POST "$API" \
          -H "Authorization: Bearer ${SECRET}" \
          -H "Content-Type: application/json" \
          -d "{ \"type\": \"A\", \"name\": \"${NAME}\", \"data\": \"${IP}\", \"ttl\": 600 }")
    fi

    STATUS_CODE=$(echo "$HTTP_RESPONSE" | grep "HTTP_STATUS:" | sed 's/HTTP_STATUS://')
    BODY=$(echo "$HTTP_RESPONSE" | grep -v "HTTP_STATUS:")

    echo "GoDaddy API HTTP Status: $STATUS_CODE"
    if [ -n "$BODY" ]; then
        echo "GoDaddy API Payload: $BODY"
    fi

    if [ "$STATUS_CODE" = "200" ] || [ "$STATUS_CODE" = "201" ]; then
        echo "Success! A-record for ${FQDN} verified and committed."
        EXTRA_IDS=$(echo "$RECORDS_JSON" | jq -r '.items[1:][].recordId // empty' 2>/dev/null || true)
        if [ -n "$EXTRA_IDS" ]; then
            echo "$EXTRA_IDS" | while IFS= read -r EXTRA_ID; do
                [ -n "$EXTRA_ID" ] || continue
                ENC_EXTRA=$(uri_encode "$EXTRA_ID")
                echo "Deleting extra A recordId $EXTRA_ID for ${FQDN}"
                curl -sS -g -X DELETE "${API}/${ENC_EXTRA}" \
                  -H "Authorization: Bearer ${SECRET}" || true
            done
        fi
    else
        echo "Warning: upsert for ${FQDN} did not succeed; will retry next loop"
    fi
}

while true; do
    IP=$(curl -sS -4 https://icanhazip.com || curl -sS -4 https://ifconfig.me || true)
    IP=$(echo "$IP" | tr -d '[:space:]')

    if echo "$IP" | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
        echo "Public IP: $IP"
        OLDIFS=$IFS
        IFS=,
        # shellcheck disable=SC2086
        set -- $RECORD_NAMES
        IFS=$OLDIFS
        for NAME in "$@"; do
            NAME=$(echo "$NAME" | tr -d '[:space:]')
            [ -n "$NAME" ] || continue
            upsert_a_record "$NAME"
        done
    else
        echo "Error: Retrieved an invalid IP address format: $IP"
    fi

    sleep "300"
done
