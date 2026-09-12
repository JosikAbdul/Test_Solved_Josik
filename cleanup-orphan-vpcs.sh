#!/usr/bin/env bash
# Limpia una VPC huerfana y TODO lo que depende de ella:
# peering, NAT Gateway, EIP, Internet Gateway, subnets, route tables, y al final la VPC.
# Uso: ./cleanup-orphan-vpcs.sh vpc-xxxxx vpc-yyyyy vpc-zzzzz ...

set -e
REGION="eu-central-1"

for VPC_ID in "$@"; do
  echo "=============================================="
  echo "Limpiando VPC: $VPC_ID"
  echo "=============================================="

  # 1. Peering connections donde esta VPC participa
  for PCX in $(aws ec2 describe-vpc-peering-connections --region $REGION \
      --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" \
      --query "VpcPeeringConnections[].VpcPeeringConnectionId" --output text); do
    echo "Borrando peering $PCX"
    aws ec2 delete-vpc-peering-connection --region $REGION --vpc-peering-connection-id "$PCX" || true
  done
  for PCX in $(aws ec2 describe-vpc-peering-connections --region $REGION \
      --filters "Name=accepter-vpc-info.vpc-id,Values=$VPC_ID" \
      --query "VpcPeeringConnections[].VpcPeeringConnectionId" --output text); do
    echo "Borrando peering $PCX"
    aws ec2 delete-vpc-peering-connection --region $REGION --vpc-peering-connection-id "$PCX" || true
  done

  # 2. NAT Gateways (hay que esperar a que terminen de borrarse)
  NAT_IDS=$(aws ec2 describe-nat-gateways --region $REGION \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending" \
    --query "NatGateways[].NatGatewayId" --output text)
  for NAT in $NAT_IDS; do
    echo "Borrando NAT Gateway $NAT (esto tarda unos minutos)..."
    aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id "$NAT"
  done
  if [ -n "$NAT_IDS" ]; then
    for NAT in $NAT_IDS; do
      aws ec2 wait nat-gateway-deleted --region $REGION --nat-gateway-ids "$NAT" || true
    done
  fi

  # 3. Elastic IPs sueltas que quedaron asociadas a NAT de esta VPC
  for ALLOC in $(aws ec2 describe-addresses --region $REGION \
      --query "Addresses[?NetworkInterfaceOwnerId!=null] | [?contains(NetworkInterfaceId, '')].AllocationId" --output text 2>/dev/null); do
    true
  done
  # (las EIPs huerfanas de verdad las limpiamos aparte al final con release-address)

  # 4. Internet Gateway
  IGW_ID=$(aws ec2 describe-internet-gateways --region $REGION \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "InternetGateways[0].InternetGatewayId" --output text)
  if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
    echo "Desasociando y borrando IGW $IGW_ID"
    aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" || true
    aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id "$IGW_ID" || true
  fi

  # 5. Subnets
  for SUBNET in $(aws ec2 describe-subnets --region $REGION \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "Subnets[].SubnetId" --output text); do
    echo "Borrando subnet $SUBNET"
    aws ec2 delete-subnet --region $REGION --subnet-id "$SUBNET" || true
  done

  # 6. Route tables (no la "main", esa se borra sola con la VPC)
  for RT in $(aws ec2 describe-route-tables --region $REGION \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" --output text); do
    echo "Borrando route table $RT"
    aws ec2 delete-route-table --region $REGION --route-table-id "$RT" || true
  done

  # 7. Security groups custom (no el "default", ese se borra solo con la VPC)
  for SG in $(aws ec2 describe-security-groups --region $REGION \
      --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" \
      --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
    echo "Borrando security group $SG"
    aws ec2 delete-security-group --region $REGION --group-id "$SG" || true
  done

  # 8. Finalmente, la VPC
  echo "Borrando VPC $VPC_ID"
  aws ec2 delete-vpc --region $REGION --vpc-id "$VPC_ID" || echo "OJO: no se pudo borrar $VPC_ID todavia, puede que falte algo dependiente."

  echo ""
done

# 9. Liberar Elastic IPs que quedaron sin asociar (de cualquier NAT ya borrado)
echo "=============================================="
echo "Revisando Elastic IPs sueltas..."
echo "=============================================="
for ALLOC in $(aws ec2 describe-addresses --region $REGION \
    --query "Addresses[?AssociationId==null].AllocationId" --output text); do
  echo "Liberando EIP suelta: $ALLOC"
  aws ec2 release-address --region $REGION --allocation-id "$ALLOC" || true
done

echo "Listo."