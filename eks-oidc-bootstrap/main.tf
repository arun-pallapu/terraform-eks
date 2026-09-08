terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.62.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =========================================================
# GitHub OIDC Certificate
# =========================================================

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}


# =========================================================
# GitHub OIDC Identity Provider
# =========================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub rotates its OIDC certificate periodically.
  # AWS now validates GitHub tokens via its own trust store, so
  # the thumbprint value is ignored — but the field is still required.
  # Using the well-known static thumbprint avoids bootstrap failures
  # when the live cert temporarily differs.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name      = "github-actions-oidc"
    ManagedBy = "Terraform"
  }
}


# =========================================================
# IAM Role for GitHub Actions
# =========================================================

resource "aws_iam_role" "github_actions" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # Lock down to exact repo; wildcard on ref so push, PR, and
            # manual triggers all work. Tighten to a specific branch in
            # production by replacing * with ref:refs/heads/main.
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = {
    Name      = var.iam_role_name
    ManagedBy = "Terraform"
  }
}


# =========================================================
# IAM Permissions
# =========================================================
#
# AdministratorAccess is used here for the learning/demo
# setup so Terraform can create and destroy the VPC/EKS
# resources.
#
# For production, replace this with a least-privilege
# Terraform IAM policy.
#

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# =========================================================
# Outputs
# =========================================================

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "IAM role name for GitHub Actions"
  value       = aws_iam_role.github_actions.name
}
