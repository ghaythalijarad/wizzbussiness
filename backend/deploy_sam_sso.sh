#!/usr/bin/env bash
set -euo pipefail

# Deploy the Regional API stack using AWS SSO profile
PROFILE="${AWS_PROFILE:-wizz-merchants-dev}"
REGION="${AWS_REGION:-us-east-1}"
STACK="${STACK_NAME:-order-receiver-regional-dev}"
STAGE="${Stage:-dev}"
TEMPLATE="${TEMPLATE_PATH:-template.yaml}"

PARAM_OVERRIDES=(
  "Stage=${STAGE}"
  "CognitoUserPoolId=us-east-1_PHPkG78b5"
  "CognitoClientId=1tl9g7nk2k2chtj5fg960fgdth"
)

cd "$(dirname "$0")"

echo "==> SAM build"
sam build --template-file "$TEMPLATE" --parallel --cached

echo "==> SAM deploy ($STACK)"
sam deploy \
  --stack-name "$STACK" \
  --resolve-s3 \
  --region "$REGION" \
  --profile "$PROFILE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-confirm-changeset \
  --parameter-overrides "${PARAM_OVERRIDES[@]}"

echo "==> Done. Check CloudFormation stack: $STACK in $REGION"
