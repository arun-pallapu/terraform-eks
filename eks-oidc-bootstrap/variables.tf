variable "aws_region" {
  description = "AWS region where the IAM resources will be managed"
  type        = string
  default     = "us-east-1"
}

variable "github_repository" {
  description = "GitHub repository in OWNER/REPOSITORY format"
  type        = string
  default     = "arun-pallapu/terraform-eks"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the IAM role"
  type        = string
  default     = "main"
}

variable "github_sub_claim" {
  description = "Full sub claim pattern from GitHub OIDC token (supports wildcards)"
  type        = string
  default     = "repo:arun-pallapu*terraform-eks*:ref:refs/heads/main"
}

variable "iam_role_name" {
  description = "IAM role name for GitHub Actions"
  type        = string
  default     = "terraform-eks-github-actions"
}
