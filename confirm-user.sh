#!/bin/bash

# Script to manually confirm a Cognito user
USER_POOL_ID="us-east-1_bDqnKdrqo"
USERNAME="g87_a@outlook.com"

echo "Confirming user: $USERNAME"
aws cognito-idp admin-confirm-sign-up --user-pool-id $USER_POOL_ID --username "$USERNAME"

if [ $? -eq 0 ]; then
    echo "User confirmed successfully!"
else
    echo "Failed to confirm user. Error code: $?"
fi
