# Solución de Prueba Técnica — Josik Mosquera
Despliegue automatizado de infraestructura multiclúster EKS en AWS con dos VPCs aisladas (gateway y backend) interconectadas mediante VPC Peering, reglas de seguridad de Security Group y CI/CD con Terraform y GitHub Actions.

## Arquitectura y Red

* **vpc-gateway**: Aloja el clúster eks-gateway y el proxy NGINX expuesto a internet por un NLB público.
* **vpc-backend**: Aloja el clúster eks-backend y el servicio privado sin acceso público.
* **VPC Peering**: Conexión privada directa entre ambas VPCs con tablas de ruteo configuradas.
* **Seguridad**: Regla de Security Group restringida para autorizar tráfico únicamente desde vpc-gateway.

## Comunicación entre Servicios

1. Se despliega backend.yaml en eks-backend y el pipeline obtiene el hostname del NLB interno.
2. El pipeline inyecta esa dirección en proxy.yaml reemplazando BACKEND_ENDPOINT_PLACEHOLDER.
3. Se despliega el proxy en eks-gateway y se valida la conectividad end-to-end con curl.

## Despliegue Automatizado

1. Clonar el repositorio y agregar los secretos AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY en GitHub Actions.
2. Hacer git push a la rama main para detonar la ejecución del pipeline.
