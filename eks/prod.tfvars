project_name = "myapp"
environment  = "prod"

region = "us-west-2"

availability_zones = [
  "us-west-2a",
  "us-west-2b"
]

eks_cluster_version = "1.33"

eks_node_instance_types = ["t3.small"]

eks_node_min_size     = 2
eks_node_max_size     = 5
eks_node_desired_size = 3
