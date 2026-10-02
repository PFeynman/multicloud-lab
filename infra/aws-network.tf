resource "aws_vpc" "multicloud-lab-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = false
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "multicloud-lab-vpc"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.multicloud-lab-vpc.id

  cidr_block        = "10.10.0.0/24"
  availability_zone = "eu-west-2a"

  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_route_table" "private-subnet-route-table" {
  vpc_id = aws_vpc.multicloud-lab-vpc.id

  tags = {
    Name = "private-subnet-route-table"
  }
}

resource "aws_route_table_association" "private-subnet-route-table-association" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-subnet-route-table.id
}
