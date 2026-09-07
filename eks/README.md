# Terraform EKS Deployment with GitHub Actions OIDC

This project provisions an Amazon EKS cluster using Terraform.

The project uses:

* Terraform
* AWS
* Amazon EKS
* Amazon VPC
* S3 remote Terraform state
* GitHub Actions
* GitHub OIDC authentication
* IAM role for GitHub Actions
* EKS managed node groups

---

## Architecture

```text
                         GitHub Repository
                    arun-pallapu/terraform-eks
                              |
                              |
                       GitHub Actions
                              |
                    GitHub OIDC Authentication
                              |
                              v
                 AWS IAM Role
          terraform-eks-github-actions
                              |
                              |
                    Terraform
                              |
             +----------------+----------------+
             |                                 |
             v                                 v
      S3 Remote State                    AWS Infrastructure
             |                                 |
             |                         +-------+-------+
             |                         |               |
             v                         v               v
   terraform.tfstate                 VPC             EKS
                                      |               |
                              +-------+-------+       |
                              |               |       |
                           Public          Private    |
                           Subnets         Subnets    |
                                                      |
                                               Managed Node Group
                                                      |
                                                   t3.small
```

---

# Project Structure

```text
terraform-eks/
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── backend.tf
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
├── README.md
└── .gitignore
```

The GitHub OIDC bootstrap is maintained separately:

```text
terraform-eks-oidc-bootstrap/
├── main.tf
└── variables.tf
```

---

# 1. Prerequisites

Install the following:

* AWS CLI
* Terraform
* kubectl
* Git
* An AWS account
* A GitHub repository

Verify:

```bash
aws --version
terraform version
kubectl version --client
git --version
```

---

# 2. AWS Authentication

For the initial bootstrap, AWS credentials are required on the machine where Terraform is executed.

Verify AWS access:

```bash
aws sts get-caller-identity
```

Example:

```text
Account: 123456789012
Arn: arn:aws:iam::123456789012:role/...
```

---

# 3. GitHub OIDC Bootstrap

The GitHub OIDC resources are created separately from the main EKS Terraform project.

Directory:

```text
terraform-eks-oidc-bootstrap/
├── main.tf
└── variables.tf
```

The bootstrap creates:

```text
AWS
│
├── GitHub OIDC Provider
│
└── IAM Role
    └── terraform-eks-github-actions
```

Go to the bootstrap directory:

```bash
cd terraform-eks-oidc-bootstrap
```

Initialize:

```bash
terraform init
```

Format:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Review:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Get the IAM role ARN:

```bash
terraform output github_actions_role_arn
```

Example:

```text
arn:aws:iam::123456789012:role/terraform-eks-github-actions
```

---

# 4. GitHub Repository Variable

The GitHub Actions workflow uses the IAM role created by the bootstrap.

In the GitHub repository:

```text
Settings
  → Secrets and variables
  → Actions
  → Variables
  → New repository variable
```

Create:

```text
Name:
AWS_ROLE_ARN
```

Value:

```text
arn:aws:iam::<AWS_ACCOUNT_ID>:role/terraform-eks-github-actions
```

Do not store AWS access keys or AWS secret keys in GitHub.

GitHub Actions authenticates to AWS using OIDC.

---

# 5. S3 Remote State

Terraform state is stored in Amazon S3.

Current bucket:

```text
terraform-eks-state-arun-2026-0905
```

Backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-eks-state-arun-2026-0905"
    key          = "eks/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The S3 bucket should have:

* Versioning enabled
* Server-side encryption enabled
* Appropriate IAM permissions

Initialize the backend:

```bash
cd terraform-eks
terraform init
```

---

# 6. Terraform Configuration

## Provider

`provider.tf` defines:

* Terraform version
* AWS provider
* AWS region

Current AWS region:

```text
us-east-1
```

---

## VPC

The project creates a VPC with CIDR:

```text
10.0.0.0/16
```

Three Availability Zones are used.

### Public Subnets

```text
10.0.101.0/24
10.0.102.0/24
10.0.103.0/24
```

### Private Subnets

```text
10.0.1.0/24
10.0.2.0/24
10.0.3.0/24
```

A single NAT Gateway is configured for the practice environment.

---

# 7. EKS Cluster

The EKS cluster is created using the Terraform AWS EKS module.

Cluster name:

```text
dev-eks
```

Kubernetes version:

```text
1.33
```

The EKS API endpoint is publicly accessible.

The Terraform-created principal is granted EKS administrator access using:

```hcl
enable_cluster_creator_admin_permissions = true
```

---

# 8. EKS Managed Node Group

The project creates one managed node group:

```text
dev-eks-nodes
```

Instance type:

```text
t3.small
```

Configuration:

```text
Minimum nodes:  1
Desired nodes:  1
Maximum nodes:  2
```

Capacity type:

```text
ON_DEMAND
```

---

# 9. EKS Add-ons

The following EKS add-ons are enabled:

```text
CoreDNS
kube-proxy
VPC CNI
EKS Pod Identity Agent
```

The configuration uses the most recent compatible versions available from AWS.

---

# 10. Local Terraform Deployment

Clone the repository:

```bash
git clone https://github.com/arun-pallapu/terraform-eks.git
```

Enter the project:

```bash
cd terraform-eks
```

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Create a plan:

```bash
terraform plan -var-file="dev.tfvars"
```

Review the resources carefully.

Apply:

```bash
terraform apply -var-file="dev.tfvars"
```

---

# 11. Verify EKS

After Terraform finishes, configure kubectl:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-eks
```

Check the cluster:

```bash
kubectl cluster-info
```

Check nodes:

```bash
kubectl get nodes
```

Expected:

```text
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-x-x.ec2.internal     Ready    <none>   ...   ...
```

Check all pods:

```bash
kubectl get pods -A
```

Check EKS add-ons:

```bash
aws eks list-addons \
  --cluster-name dev-eks \
  --region us-east-1
```

---

# 12. GitHub Actions

The workflow is located at:

```text
.github/workflows/terraform.yml
```

The workflow performs:

```text
Checkout
   ↓
GitHub OIDC authentication
   ↓
Assume AWS IAM Role
   ↓
Verify AWS identity
   ↓
Install Terraform
   ↓
terraform fmt
   ↓
terraform init
   ↓
terraform validate
   ↓
terraform plan
   ↓
terraform apply
```

AWS credentials are obtained dynamically using GitHub OIDC.

No permanent AWS access key is required in GitHub.

---

# 13. Terraform State

Terraform state is stored remotely:

```text
S3
└── terraform-eks-state-arun-2026-0905
    └── eks/
        └── dev/
            └── terraform.tfstate
```

Do not commit Terraform state to Git.

The `.gitignore` file excludes:

```text
*.tfstate
*.tfstate.*
```

---

# 14. Useful Terraform Commands

Initialize:

```bash
terraform init
```

Format:

```bash
terraform fmt
```

Check formatting:

```bash
terraform fmt -check -recursive
```

Validate:

```bash
terraform validate
```

Plan:

```bash
terraform plan -var-file="dev.tfvars"
```

Apply:

```bash
terraform apply -var-file="dev.tfvars"
```

Show outputs:

```bash
terraform output
```

Show state:

```bash
terraform state list
```

Destroy:

```bash
terraform destroy -var-file="dev.tfvars"
```

---

# 15. Destroy EKS Infrastructure

When finished with the practice environment:

```bash
cd terraform-eks
terraform destroy -var-file="dev.tfvars"
```

This destroys the infrastructure managed by the main Terraform project, including:

```text
EKS Cluster
EKS Node Group
VPC
Subnets
NAT Gateway
Other Terraform-managed EKS/VPC resources
```

The separate GitHub OIDC bootstrap resources are not destroyed by this command.

---

# 16. Destroy GitHub OIDC Bootstrap

Only destroy the bootstrap when you no longer need GitHub Actions to authenticate to AWS.

```bash
cd terraform-eks-oidc-bootstrap
terraform destroy
```

This removes the separately managed:

```text
GitHub OIDC Provider
IAM Role
IAM Policy Attachment
```

---

# 17. Important Security Notes

The bootstrap IAM role currently uses:

```text
AdministratorAccess
```

This is acceptable for learning and practice.

For production, replace it with a least-privilege IAM policy that allows only the AWS resources Terraform needs.

The GitHub OIDC trust policy should also be restricted to the intended repository and branch.

Never commit:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
Terraform state files
Private keys
Passwords
API tokens
```

---

# 18. Environment Variables

The current practice configuration uses:

```text
Environment: dev
Region:      us-east-1
Cluster:     dev-eks
Kubernetes:  1.33
Node type:   t3.small
Nodes:       1-2
```

These values can be changed through:

```text
dev.tfvars
```

Example:

```hcl
region = "us-east-1"

environment = "dev"

cluster_name = "eks"

eks_cluster_version = "1.33"

eks_node_instance_types = [
  "t3.small"
]

eks_node_min_size     = 1
eks_node_max_size     = 2
eks_node_desired_size = 1
```

---

# 19. Deployment Flow

The complete deployment flow is:

```text
                    AWS
                     │
                     │
          Bootstrap Terraform
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
   GitHub OIDC Provider      IAM Role
                              │
                              │
                              ▼
                     GitHub Actions
                              │
                              │ OIDC
                              ▼
                         AWS STS
                              │
                              ▼
                    Assume IAM Role
                              │
                              ▼
                         Terraform
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
               S3 Backend          AWS Resources
                    │                   │
                    │              ┌────┴────┐
                    │              │         │
                    │              ▼         ▼
                    │             VPC       EKS
                    │                        │
                    │                        ▼
                    │                 Managed Nodes
                    │
                    ▼
             terraform.tfstate
```

---

# 20. Project Goal

This project demonstrates a practical DevOps workflow for provisioning AWS infrastructure using:

```text
Terraform
   +
AWS
   +
EKS
   +
GitHub Actions
   +
OIDC
   +
S3 Remote State
```

The main objective is to avoid storing long-lived AWS credentials in GitHub Actions while maintaining remote Terraform state and automated infrastructure deployment.
