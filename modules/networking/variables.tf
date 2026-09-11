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

variable "public_subnet_cidr" {
  description = "CIDR de la subred pública (solo para el NAT Gateway)"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para las subredes privadas (una por AZ)"
  type        = list(string)
}
