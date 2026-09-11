module "eks_gateway" {
  source     = "./modules/eks"
  cluster_name = "gateway"
  vpc_id     = module.vpc_gateway.vpc_id
  subnet_ids = module.vpc_gateway.private_subnet_ids
}

module "eks_backend" {
  source     = "./modules/eks"
  cluster_name = "backend"
  vpc_id     = module.vpc_backend.vpc_id
  subnet_ids = module.vpc_backend.private_subnet_ids
}
