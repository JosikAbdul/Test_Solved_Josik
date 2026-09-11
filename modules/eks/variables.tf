variable "cluster_name" {
  description = "Nombre corto del cluster (ej: gateway o backend)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde va el cluster"
  type        = string
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas donde corre el cluster"
  type        = list(string)
}

variable "node_instance_type" {
  description = "Tipo de instancia EC2 para los nodos"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "additional_security_group_ids" {
  description = "Security groups adicionales para el node group"
  type        = list(string)
  default     = []
}
