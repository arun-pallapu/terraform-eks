output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "API endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version running on the EKS cluster."
  value       = module.eks.cluster_version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID associated with the EKS cluster."
  value       = module.eks.cluster_security_group_id
}

output "eks_vpc_id" {
  description = "VPC ID where the EKS cluster is deployed."
  value       = module.vpc.vpc_id
}

output "eks_private_subnet_ids" {
  description = "Private subnet IDs used by the EKS cluster."
  value       = module.vpc.private_subnets
}

output "eks_node_group_name" {
  description = "Name of the EKS managed node group."
  value       = module.eks.eks_managed_node_groups["application"].node_group_name
}
