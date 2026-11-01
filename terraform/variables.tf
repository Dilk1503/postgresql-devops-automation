
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-north-1"
}

variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "eu-north-1a"
}

variable "vpc_cidr" {
  description = "Dedicated PostgreSQL VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "PostgreSQL public subnet CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "jenkins_security_group_id" {
  type    = string
  default = "sg-013f7334bb4138fb7"
}

variable "jenkins_vpc_id" {
  type    = string
  default = "vpc-0d9e6954880266b03"
}

variable "jenkins_vpc_cidr" {
  type    = string
  default = "172.31.0.0/16"
}

variable "jenkins_route_table_id" {
  type    = string
  default = "rtb-0941423c384cb9b35"
}
