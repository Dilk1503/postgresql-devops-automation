
output "vpc_id" {
  value = aws_vpc.postgres_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.postgres_vpc.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.postgres_public_subnet.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.postgres_igw.id
}

output "route_table_id" {
  value = aws_route_table.postgres_public_rt.id
}
output "postgres_instance_id" {
  value = aws_instance.postgres_server.id
}

output "postgres_private_ip" {
  value = aws_instance.postgres_server.private_ip
}

output "postgres_public_ip" {
  value = aws_instance.postgres_server.public_ip
}
