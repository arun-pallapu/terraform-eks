region = "us-east-1"

environment = "dev"

cluster_name = "eks"

eks_cluster_version = "1.33"

eks_node_instance_types = [
  "m7i-flex.large"
]

eks_node_min_size     = 1
eks_node_max_size     = 2
eks_node_desired_size = 1

