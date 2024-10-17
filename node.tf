resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# Attach necessary policies to the node group role
resource "aws_iam_role_policy_attachment" "node_group_policy_1" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_group_policy_2" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_group_policy_cni" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create the EKS Node Group
resource "aws_eks_node_group" "example" {
  cluster_name    = "terraform-eks" 
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = ["subnet-0bba53b4753db30cc", "subnet-0cfa31d6389e59428"] # Replace with your subnet IDs

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

   instance_types = ["t3.medium"] # Change as needed; this is now a list
  disk_size     = 20             # EBS volume size in GiB

  tags = {
    Name = "example-node-group"
  }

  depends_on = [aws_iam_role_policy_attachment.node_group_policy_1]
}