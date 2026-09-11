resource "aws_security_group_rule" "backend_allow_from_gateway" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [module.vpc_gateway.vpc_cidr_block]
  security_group_id = module.eks_backend.cluster_security_group_id
  description       = "Permite trafico solo desde vpc-gateway hacia eks-backend"
}
