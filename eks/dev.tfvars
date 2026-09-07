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

