# Solución de Prueba Técnica Rapyd Sentinel — Josik Mosquera

Prueba técnica: dos dominios de red aislados (vpc-gateway público y vpc-backend privado), cada uno con su propio clúster EKS, conectados por VPC Peering privado, desplegados 100% vía Terraform + GitHub Actions. Flujo end-to-end verificado automáticamente por el propio pipeline (paso "Wait for public Load Balancer and verify end-to-end").

Cómo clonar y correr el proyecto
Clona el repositorio:
bash
   git clone https://github.com/JosikAbdul/Test_Solved_Josik.git
   cd Test_Solved_Josik
Agrega los secrets en GitHub (Settings → Secrets and variables → Actions):
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
Haz git push a main. El pipeline (.github/workflows/terraform.yml) valida, planea y aplica Terraform, y despliega el backend y el proxy, terminando con una verificación real (curl) del flujo completo.

No se aplica Terraform manualmente desde ningún equipo local para el flujo normal — solo se usó terraform en local durante el desarrollo para depurar y hacer import de recursos ya existentes en la cuenta (ver abajo).

Estructura del proyecto
provider.tf              # Provider AWS + backend remoto S3 para el state
networking.tf              # Llama al modulo networking dos veces (gateway y backend)
eks.tf                       # Llama al modulo eks dos veces (eks-gateway y eks-backend)
peering.tf                   # VPC Peering + rutas cruzadas + DNS resolution habilitado
security.tf                   # Restringe el backend a solo aceptar trafico desde vpc-gateway
modules/networking/          # VPC + subnets publicas/privadas por AZ + NAT + IGW + rutas
modules/eks/                   # Cluster EKS + node group; roles IAM via data source (ya existian)
kubernetes/backend.yaml        # Deployment "Hello from backend" + Service NLB interno
kubernetes/proxy.yaml          # ConfigMap NGINX + Deployment proxy + Service NLB publico
.github/workflows/terraform.yml # Pipeline: validate -> plan -> apply -> deploy k8s -> verify
Arquitectura de red
vpc-gateway: subnets privadas y publicas en 2 AZs de eu-central-1, NAT Gateway propio. Aqui corre eks-gateway y el proxy NGINX, unico punto expuesto a internet (via NLB publico).
vpc-backend: misma estructura. Aqui corre eks-backend y el servicio interno, sin entrada publica.
VPC Peering (peering.tf, auto-aceptado) conecta ambas VPCs, con rutas cruzadas y resolucion DNS habilitada en ambos sentidos (allow_remote_vpc_dns_resolution = true) — imprescindible para que el proxy pueda resolver el hostname del NLB interno del backend.
Security Group: la regla de ingreso se aplica sobre el security group que EKS adjunta automaticamente al control plane y a los nodos del backend, permitiendo trafico solo desde el CIDR de vpc-gateway.
Cómo el proxy alcanza el backend

El backend expone su servicio como un NLB interno (aws-load-balancer-internal: "true"). El pipeline:

Despliega el backend y obtiene el hostname del NLB interno.
Sustituye BACKEND_ENDPOINT_PLACEHOLDER en el ConfigMap del proxy con ese hostname real.
Despliega el proxy NGINX (con anotacion aws-load-balancer-type: "nlb" para que su Service publico tambien sea un NLB, no un Load Balancer Clasico).
Verifica con curl real que el flujo gateway -> backend funciona.
Pipeline de CI/CD (GitHub Actions)

Un job con pasos en orden: Checkout, Terraform Init/Validate/Plan/Apply, Deploy backend + espera de su LB interno, Deploy proxy (con reemplazo del placeholder) + espera de su LB publico + verificacion curl end-to-end. Trigger: push a main.

Roles IAM usados (prefijos permitidos)
eks-<gateway|backend>-cluster-role y eks-<gateway|backend>-node-role. Estos roles ya existian pre-creados en la cuenta (la cuenta de prueba esta pre-provisionada con ellos, en lugar de dar permiso de iam:CreateRole sin restriccion). El modulo eks los referencia con data "aws_iam_role" en vez de crearlos con resource, y solo les adjunta las policies necesarias — sin crear ningun rol nuevo fuera de los prefijos permitidos.
Problemas reales encontrados durante el desarrollo (y como se resolvieron)

Roles IAM EntityAlreadyExists: los 4 roles esperados ya existian en la cuenta. Solucion: usar data "aws_iam_role" en vez de resource, y terraform import para las rutas de red que tambien ya existian tras iteraciones previas.
Version de Kubernetes no soportada (unsupported Kubernetes version 1.29): se quito el pin de version del cluster para que AWS use la version estable vigente automaticamente.
InternetGatewayLimitExceeded: causado por no tener backend remoto de Terraform al principio — cada corrida de GitHub Actions (sin estado compartido) creaba VPCs nuevas sin destruir las anteriores. Se resolvio creando un bucket S3 para el backend "s3" de Terraform y limpiando manualmente las VPCs huerfanas con un script de AWS CLI.
Load Balancer publico del proxy sin targets sanos (Target.NotInUse / zona no habilitada): la subnet publica original solo existia en una AZ. Se cambio el modulo de networking para crear una subnet publica por cada AZ, etiquetadas kubernetes.io/role/elb para que Kubernetes las detecte automaticamente.
curl al proxy se quedaba colgado indefinidamente: el proxy no podia resolver el hostname del NLB interno del backend porque, por defecto, el VPC Peering no permite resolucion DNS cruzada entre VPCs. Se habilito allow_remote_vpc_dns_resolution = true en ambos lados (requester/accepter) del aws_vpc_peering_connection.
RouteAlreadyExists al separar las rutas de un bloque route {} inline a recursos aws_route independientes: un aws_route_table con bloque route {} inline se considera dueño exclusivo de sus rutas y borra cualquier otra (como las del peering) que no este ahi declarada. Se migraron las rutas de NAT/IGW a recursos aws_route separados y se importaron las que ya existian en AWS para no recrearlas.
Trade-offs y limitaciones (por el limite de 3 dias)
Autenticacion: AWS_ACCESS_KEY_ID/SECRET como GitHub Secrets, no OIDC federation (bonus opcional).
Backend S3 sin tabla DynamoDB de lock: la cuenta de prueba no tiene permiso dynamodb:CreateTable. El riesgo de aplicar en paralelo es bajo porque solo el pipeline aplica, pero en un entorno real con multiples colaboradores esto es indispensable.
TLS: el gateway expone HTTP plano.
tflint: no integrado en el pipeline.
Observabilidad: sin metricas ni logs centralizados.
NetworkPolicy: no hay restriccion de trafico a nivel de pod/namespace.
Que mejoraria a continuacion
Migrar a OIDC federation para GitHub Actions.
Crear la tabla DynamoDB de lock (o usar S3 lockfile nativo de Terraform 1.10+) si se habilita el permiso dynamodb:CreateTable.
TLS en el gateway (ACM + NLB con TLS listener).
tflint y kubeconform en el pipeline.
Service Mesh o mTLS entre gateway y backend.
NetworkPolicy de Kubernetes.
Observabilidad: CloudWatch Container Insights.