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
