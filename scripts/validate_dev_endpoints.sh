#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com}"
STAGE="${STAGE:-dev}"

curl_do() {
  local method="${1}"; shift
  local url="${1}"; shift
  echo "\n## ${method} ${url}" >&2
  curl -sS -i -X "${method}" "$@" "${url}" | sed -n '1,40p'
}

main() {
  echo "Testing public endpoints on ${API_BASE}/${STAGE}" >&2
  curl_do GET    "${API_BASE}/${STAGE}/auth/health"
  curl_do GET    "${API_BASE}/${STAGE}/categories"
  curl_do GET    "${API_BASE}/${STAGE}/categories/business-type/restaurant"
  curl_do GET    "${API_BASE}/${STAGE}/business-subcategories"
  curl_do GET    "${API_BASE}/${STAGE}/business-subcategories/business-type/restaurant"
  echo "\nCORS preflight checks" >&2
  curl_do OPTIONS "${API_BASE}/${STAGE}/categories" -H "Origin: https://example.com" -H "Access-Control-Request-Method: GET"
}

main "$@"
