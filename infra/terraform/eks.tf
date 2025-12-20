####
# EKS Cluster
####

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  name               = local.name
  kubernetes_version = "1.34"

  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "BOTTLEROCKET_ARM_64" # BOTTLEROCKET_ARM_64 / BOTTLEROCKET_x86_64
      instance_types = ["m8g.large"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }
  }

  node_security_group_tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })

  access_entries = {
    admin_role_access = {
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/kaykyfreitas"
      kubernetes_groups = [
        "system:masters"
      ]
    }
  }

  tags = local.tags
}