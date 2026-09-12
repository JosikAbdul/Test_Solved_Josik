module "vpc_gateway" {
  source               = "./modules/networking"
  vpc_name             = "vpc-gateway"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["eu-central-1a", "eu-central-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "vpc_backend" {
  source               = "./modules/networking"
  vpc_name             = "vpc-backend"
  vpc_cidr             = "10.1.0.0/16"
  azs                  = ["eu-central-1a", "eu-central-1b"]
  public_subnet_cidrs  = ["10.1.0.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
}