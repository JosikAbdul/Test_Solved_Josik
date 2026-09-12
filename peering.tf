resource "aws_vpc_peering_connection" "gateway_to_backend" {
  vpc_id      = module.vpc_gateway.vpc_id
  peer_vpc_id = module.vpc_backend.vpc_id
  auto_accept = true

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "gateway-to-backend-peering"
  }
}

resource "aws_route" "gateway_to_backend" {
  route_table_id            = module.vpc_gateway.private_route_table_id
  destination_cidr_block    = module.vpc_backend.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.gateway_to_backend.id
}

resource "aws_route" "backend_to_gateway" {
  route_table_id            = module.vpc_backend.private_route_table_id
  destination_cidr_block    = module.vpc_gateway.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.gateway_to_backend.id
}