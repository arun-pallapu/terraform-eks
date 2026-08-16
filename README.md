# Terraform Resources

This project demonstrates how to use **Terraform variables** and **`.tfvars` files** to manage environment-specific configuration.

---

## Project Structure

```text
terraform-eks/
├── .github/
│   └── workflows/
│       └── terraform.yml
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
└── README.md
```

---

## 1. `variables.tf`

`variables.tf` defines the inputs that Terraform accepts.

**Example:**

```hcl
variable "region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "us-west-2"
}
```

This tells Terraform:

> Terraform has a variable called `region`, and its default value is `us-west-2`.

**Common Variable Structure:**

```hcl
variable "variable_name" {
  description = "Description of the variable."
  type        = string
  default     = "default-value"
}
```

---

## 2. Why Use `.tfvars` Files?

A `.tfvars` file is used to provide or override values for Terraform variables.

This becomes particularly useful when you want to use the same Terraform code for multiple environments.

```
         Same Terraform Code
                 |
      +----------+----------+
      |                     |
  dev.tfvars            prod.tfvars
      |                     |
      v                     v
DEV Environment       PROD Environment
```

You don't need to create separate `main.tf` files for each environment.

---

## 3. `dev.tfvars`

Example development environment configuration:

```hcl
project_name = "myapp"
environment  = "dev"

region = "us-east-1"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

eks_cluster_version = "1.33"

eks_node_instance_types = ["t3.small"]

eks_node_min_size     = 1
eks_node_max_size     = 1
eks_node_desired_size = 1
```

This configuration tells Terraform to deploy the development environment with:

| Setting            | Value                    |
|--------------------|--------------------------|
| Region             | `us-east-1`              |
| Environment        | `dev`                    |
| Availability Zones | `us-east-1a`, `us-east-1b` |
| EKS Version        | `1.33`                   |
| Node Type          | `t3.small`               |
| Minimum Nodes      | `1`                      |
| Maximum Nodes      | `1`                      |
| Desired Nodes      | `1`                      |

---

## 4. `prod.tfvars`

You can use different values for production while keeping the same Terraform code.

**Example:**

```hcl
project_name = "myapp"
environment  = "prod"

region = "us-west-2"

availability_zones = [
  "us-west-2a",
  "us-west-2b"
]

eks_cluster_version = "1.33"

eks_node_instance_types = ["m5.large"]

eks_node_min_size     = 2
eks_node_max_size     = 5
eks_node_desired_size = 3
```

The same `main.tf` can now be used for both environments.

---

## 5. Running the Development Environment

To create a plan using `dev.tfvars`:

```bash
terraform plan -var-file="dev.tfvars"
```

To create the infrastructure:

```bash
terraform apply -var-file="dev.tfvars"
```

Terraform will use the values from `dev.tfvars` instead of the defaults defined in `variables.tf`.

---

## 6. Running the Production Environment

To create a production plan:

```bash
terraform plan -var-file="prod.tfvars"
```

To create the production infrastructure:

```bash
terraform apply -var-file="prod.tfvars"
```

---

## 7. Variable Precedence

Terraform can get variable values from several places. For this setup, the important concept is:

```
variables.tf
     |
     | defines variable + default
     v
dev.tfvars
     |
     | overrides default
     v
Terraform
```

For example, `variables.tf` contains:

```hcl
variable "region" {
  default = "us-west-2"
}
```

But `dev.tfvars` contains:

```hcl
region = "us-east-1"
```

When you run:

```bash
terraform plan -var-file="dev.tfvars"
```

Terraform uses `us-east-1` instead of the default `us-west-2`.

---

## 8. Why `.tfvars` Is Useful

Using `.tfvars` files allows you to maintain:

- One reusable `main.tf`
- One `variables.tf`
- One `outputs.tf`
- Separate configuration for each environment

```
Terraform Code
     |
     +-- dev.tfvars   →   DEV
     |
     +-- stage.tfvars →   STAGE
     |
     +-- prod.tfvars  →   PROD
```

This is a common approach for managing environment-specific Terraform configuration.

---

## 9. Important Note

You don't have to use `terraform.tfvars` specifically. You can use:

- `dev.tfvars`
- `prod.tfvars`
- `stage.tfvars`

and explicitly select the required file:

```bash
terraform plan -var-file="dev.tfvars"
```

> A file named `terraform.tfvars` is **automatically loaded** by Terraform.  
> Custom files such as `dev.tfvars` or `prod.tfvars` require the `-var-file` option.

---

## 10. Typical Terraform Workflow

For the development environment:

```bash
# Initialize the working directory
terraform init

# Format configuration files
terraform fmt

# Validate the configuration
terraform validate

# Preview the changes
terraform plan -var-file="dev.tfvars"

# Apply the changes
terraform apply -var-file="dev.tfvars"
```

When you're finished with the practice EKS environment:

```bash
# Destroy the infrastructure
terraform destroy -var-file="dev.tfvars"
```

This removes all infrastructure created using the development configuration.
