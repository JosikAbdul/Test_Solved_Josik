output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint de la API de Kubernetes"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Datos del certificado de la CA del cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_role_arn" {
  description = "ARN del rol de IAM del cluster"
  value       = data.aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "ARN del rol de IAM de los nodos"
  value       = data.aws_iam_role.node.arn
}

output "cluster_security_group_id" {
  description = "ID del Security Group asociado al cluster EKS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
