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

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
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
          }

          StringLike = {
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
