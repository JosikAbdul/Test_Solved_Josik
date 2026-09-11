variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Version de Kubernetes"
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "IDs de las subredes privadas donde corre el cluster"
  type        = list(string)
}

variable "instance_types" {
  description = "Tipos de instancia EC2 para los nodos del node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Numero deseado de nodos"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Numero minimo de nodos"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Numero maximo de nodos"
  type        = number
  default     = 2
}

variable "additional_security_group_ids" {
  description = "Security groups adicionales para el node group"
  type        = list(string)
  default     = []
}
variable "vpc_id" {
  description = "ID de la VPC donde se despliega el cluster"
  type        = string
  default     = null
}
