variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.33"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}



