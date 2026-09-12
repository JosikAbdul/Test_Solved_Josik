variable "vpc_name" {
  description = "Nombre de la VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
}

variable "azs" {
  description = "Zonas de disponibilidad a usar"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para las subredes publicas (una por AZ, para el Load Balancer)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para las subredes privadas (una por AZ)"
  type        = list(string)
}
