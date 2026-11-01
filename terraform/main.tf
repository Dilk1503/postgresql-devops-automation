
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "dileep-postgresql-tf-state-359813812441-eu-north-1"
    key          = "postgresql/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Dedicated PostgreSQL VPC

resource "aws_vpc" "postgres_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "postgres-devops-vpc"
    Environment = var.environment
    Project     = "PostgreSQL-One-Click"
  }
}

# 2. Public Subnet

resource "aws_subnet" "postgres_public_subnet" {
  vpc_id                  = aws_vpc.postgres_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "postgres-public-subnet"
  }
}

# 3. Internet Gateway

resource "aws_internet_gateway" "postgres_igw" {
  vpc_id = aws_vpc.postgres_vpc.id

  tags = {
    Name = "postgres-devops-igw"
  }
}

# 4. Route Table

resource "aws_route_table" "postgres_public_rt" {
  vpc_id = aws_vpc.postgres_vpc.id

  tags = {
    Name = "postgres-public-route-table"
  }
}

# 5. Route Table Association

resource "aws_route_table_association" "postgres_public_rta" {
  subnet_id      = aws_subnet.postgres_public_subnet.id
  route_table_id = aws_route_table.postgres_public_rt.id
}

# 6. VPC Peering

resource "aws_vpc_peering_connection" "postgres_peer" {
  vpc_id      = aws_vpc.postgres_vpc.id
  peer_vpc_id = var.jenkins_vpc_id
  auto_accept = true

  tags = {
    Name = "jenkins-postgres-vpc-peering"
  }
}

# 7. PostgreSQL Security Group

resource "aws_security_group" "postgres_sg" {
  name        = "postgres-devops-sg"
  description = "Allow SSH and PostgreSQL access from Jenkins"
  vpc_id      = aws_vpc.postgres_vpc.id

  ingress {
    description     = "SSH from Jenkins security group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.jenkins_security_group_id]
  }

  ingress {
    description     = "PostgreSQL from Jenkins security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.jenkins_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc_peering_connection.postgres_peer
  ]

  tags = {
    Name    = "postgres-devops-sg"
    Project = "PostgreSQL-One-Click"
  }
}

# 8. Internet Route

resource "aws_route" "postgres_internet_route" {
  route_table_id         = aws_route_table.postgres_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.postgres_igw.id
}

# 9. PostgreSQL VPC to Jenkins VPC Route

resource "aws_route" "postgres_to_jenkins" {
  route_table_id            = aws_route_table.postgres_public_rt.id
  destination_cidr_block    = var.jenkins_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.postgres_peer.id
}

# 10. Jenkins VPC to PostgreSQL VPC Route

resource "aws_route" "jenkins_to_postgres" {
  route_table_id            = var.jenkins_route_table_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.postgres_peer.id
}

# 11. Ubuntu 24.04 LTS AMI

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 12. PostgreSQL EC2 Instance

resource "aws_instance" "postgres_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.postgres_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.postgres_sg.id]
  key_name                    = "postgres-devops-key"
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "postgres-devops-server"
    Environment = var.environment
    Project     = "PostgreSQL-One-Click"
  }
}

