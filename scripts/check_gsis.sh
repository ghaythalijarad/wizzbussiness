#!/usr/bin/env bash
set -euo pipefail

PROFILE="${AWS_PROFILE:-default}"
REGION="${AWS_REGION:-us-east-1}"

TABLES=(
  "WhizzMerchants_Products|BusinessIdIndex"
  "WhizzMerchants_Businesses|email-index"
  "WhizzMerchants_Users|email-index"
  "WhizzMerchants_Categories|BusinessTypeIndex"
  "WhizzMerchants_BusinessSubcategories|BusinessTypeIndex"
)

check_gsi() {
  local table="$1"; local gsi="$2"
  aws --profile "$PROFILE" --region "$REGION" dynamodb describe-table --table-name "$table" \
    --query "Table.GlobalSecondaryIndexes[?IndexName=='$gsi'].IndexStatus | [0]" --output text 2>/dev/null || echo "MISSING"
}

printf "Checking DynamoDB GSIs in %s (profile: %s)\n\n" "$REGION" "$PROFILE"
printf "%-40s %-28s %s\n" "TABLE" "GSI" "STATUS"
printf "%-40s %-28s %s\n" "----------------------------------------" "----------------------------" "------------"
for entry in "${TABLES[@]}"; do
  IFS='|' read -r table gsi <<<"$entry"
  status=$(check_gsi "$table" "$gsi")
  printf "%-40s %-28s %s\n" "$table" "$gsi" "$status"
  if [[ "$status" == "MISSING" || "$status" == "None" ]]; then
    echo "  -> Missing or not active. Create the GSI and backfill if required."
  fi
done
