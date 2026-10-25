resource "aws_vpc" "multicloud_lab_vpc" {
  cidr_block           = local.aws_vpc_cidr
  enable_dns_hostnames = false
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "multicloud-lab-vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.multicloud_lab_vpc.id

  cidr_block        = local.aws_private_subnet_cidr
  availability_zone = local.aws_az

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.multicloud_lab_vpc.id

  tags = {
    Name = "private-subnet-route-table"
  }
}

resource "aws_route_table_association" "private_subnet" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}
