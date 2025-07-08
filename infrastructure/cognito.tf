# AWS Cognito Resources for Hadhir Business App

# Data sources
data "aws_caller_identity" "current" {}

# SES Domain Identity for Cognito Email
resource "aws_ses_domain_identity" "hadhir_business_domain" {
  domain = "hadhir-business.com"
}

# SES Email Identity (for testing without domain verification)
resource "aws_ses_email_identity" "hadhir_business_noreply" {
  email = "noreply@hadhir-business.com"
}

# For immediate testing, use a verified email address instead
resource "aws_ses_email_identity" "test_email" {
  email = "ghaythallaheebi@gmail.com"  # Replace with your verified email
}

# SES Configuration Set (optional, for tracking)
resource "aws_ses_configuration_set" "hadhir_business_emails" {
  name = "hadhir-business-cognito-emails"

  delivery_options {
    tls_policy = "Require"
  }

  tracking_options {
    custom_redirect_domain = "hadhir-business.com"
  }

  tags = {
    Name        = "hadhir-business-cognito-emails"
    Environment = var.environment
    Project     = "hadhir-business"
  }
}

resource "aws_cognito_user_pool" "hadhir_business_user_pool" {
  name = "hadhir-business-user-pool"

  # User attributes
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email configuration - Using SES for better deliverability
  email_configuration {
    email_sending_account  = "DEVELOPER"
    source_arn            = aws_ses_email_identity.test_email.arn
    from_email_address    = "Hadhir Business <ghaythallaheebi@gmail.com>"
    reply_to_email_address = "ghaythallaheebi@gmail.com"
  }

  # User attributes
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "given_name"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "family_name"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Verification messages
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Hadhir Business - Verify Your Account"
    email_message        = "Welcome to Hadhir Business! Your verification code is {####}"
  }

  tags = {
    Name        = "hadhir-business-user-pool"
    Environment = var.environment
    Project     = "hadhir-business"
  }
}

# User Pool Client
resource "aws_cognito_user_pool_client" "hadhir_business_client" {
  name         = "hadhir-business-app-client"
  user_pool_id = aws_cognito_user_pool.hadhir_business_user_pool.id

  # Client settings
  generate_secret = false # Public client for mobile apps
  
  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Token validity
  access_token_validity  = 24    # 24 hours
  id_token_validity      = 24    # 24 hours
  refresh_token_validity = 30    # 30 days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified",
    "given_name",
    "family_name"
  ]

  write_attributes = [
    "email",
    "given_name",
    "family_name"
  ]
}

# Identity Pool (for AWS service access)
resource "aws_cognito_identity_pool" "hadhir_business_identity_pool" {
  identity_pool_name               = "hadhir_business_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.hadhir_business_client.id
    provider_name           = aws_cognito_user_pool.hadhir_business_user_pool.endpoint
    server_side_token_check = false
  }

  tags = {
    Name        = "hadhir-business-identity-pool"
    Environment = var.environment
    Project     = "hadhir-business"
  }
}

# IAM role for authenticated users
resource "aws_iam_role" "cognito_authenticated_role" {
  name = "hadhir_business_cognito_authenticated_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.hadhir_business_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

# Policy for authenticated users
resource "aws_iam_role_policy" "cognito_authenticated_policy" {
  name = "hadhir_business_cognito_authenticated_policy"
  role = aws_iam_role.cognito_authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach role to identity pool
resource "aws_cognito_identity_pool_roles_attachment" "hadhir_business_identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.hadhir_business_identity_pool.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated_role.arn
  }
}

# IAM Role for Cognito to send emails via SES
resource "aws_iam_role" "cognito_ses_role" {
  name = "hadhir_business_cognito_ses_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "hadhir-business-cognito-ses-role"
    Environment = var.environment
    Project     = "hadhir-business"
  }
}

# IAM Policy for Cognito to send emails via SES
resource "aws_iam_role_policy" "cognito_ses_policy" {
  name = "hadhir_business_cognito_ses_policy"
  role = aws_iam_role.cognito_ses_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = [
          aws_ses_domain_identity.hadhir_business_domain.arn,
          aws_ses_email_identity.hadhir_business_noreply.arn,
          aws_ses_email_identity.test_email.arn,
          "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/*"
        ]
      }
    ]
  })
}

# Outputs
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.hadhir_business_user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.hadhir_business_client.id
}

output "cognito_identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = aws_cognito_identity_pool.hadhir_business_identity_pool.id
}

output "cognito_region" {
  description = "AWS region where Cognito resources are created"
  value       = var.aws_region
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.hadhir_business_user_pool.endpoint
}

output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.hadhir_business_domain.arn
}

output "ses_email_identity_arn" {
  description = "ARN of the SES email identity"
  value       = aws_ses_email_identity.hadhir_business_noreply.arn
}

output "cognito_ses_role_arn" {
  description = "ARN of the Cognito SES role"
  value       = aws_iam_role.cognito_ses_role.arn
}
