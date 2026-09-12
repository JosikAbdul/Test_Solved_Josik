resource "aws_security_group_rule" "backend_allow_from_gateway" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [module.vpc_gateway.vpc_cidr_block]
  security_group_id = module.eks_backend.cluster_security_group_id
  description       = "Permite trafico solo desde vpc-gateway hacia eks-backend"
}

resource "aws_security_group_rule" "gateway_allow_nodeport_from_internet" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks_gateway.cluster_security_group_id
  description       = "Permite trafico del Load Balancer publico hacia los nodos de eks-gateway"
}

resource "aws_security_group_rule" "backend_allow_self_healthcheck" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [module.vpc_backend.vpc_cidr_block]
  security_group_id = module.eks_backend.cluster_security_group_id
  description       = "Permite el health check del Load Balancer interno (trafico desde la propia VPC)"
}
