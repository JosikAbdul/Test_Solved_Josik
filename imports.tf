import {
  to = module.eks_gateway.aws_iam_role.cluster
  id = "eks-gateway-cluster-role"
}

import {
  to = module.eks_gateway.aws_iam_role.node
  id = "eks-gateway-node-role"
}

import {
  to = module.eks_backend.aws_iam_role.cluster
  id = "eks-backend-cluster-role"
}

import {
  to = module.eks_backend.aws_iam_role.node
  id = "eks-backend-node-role"
}
