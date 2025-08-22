#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com}"
STAGE="${STAGE:-dev}"
EMAIL="${EMAIL:-}"
PASSWORD="${PASSWORD:-}"

if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
  echo "Usage: EMAIL=you@example.com PASSWORD=secret $0" >&2
  exit 2
fi

signin() {
  curl -sS -i -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
    "${API_BASE}/${STAGE}/auth/signin"
}

get_user_businesses() {
  local token="$1"
  curl -sS -i \
    -H "Authorization: Bearer ${token}" \
    "${API_BASE}/${STAGE}/auth/user-businesses"
}

parse_body() {
  # Split headers from body on the first empty line (handles CRLF) and print body only
  awk 'BEGIN{blank=0} blank{print} NF==0{blank=1}'
}

main() {
  echo "\n## POST /auth/signin" >&2
  RESP=$(signin)
  echo "$RESP" | sed -n '1,20p'
  BODY=$(echo "$RESP" | parse_body)
  ACCESS=$(echo "$BODY" | jq -r '.data.AccessToken // .accessToken // .AccessToken // .idToken // .IdToken // empty')
  if [[ -z "$ACCESS" || "$ACCESS" == "null" ]]; then
    echo "\n!! Could not parse access token from signin response. Ensure function returns token fields." >&2
    echo "Response body:" >&2
    echo "$BODY" | sed -n '1,80p' >&2
    exit 1
  fi
  echo "\nParsed AccessToken (truncated): ${ACCESS:0:20}..." >&2
  echo "\n## GET /auth/user-businesses" >&2
  get_user_businesses "$ACCESS" | sed -n '1,40p'
}

main "$@"
