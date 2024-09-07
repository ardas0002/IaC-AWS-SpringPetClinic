# Define VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Define Public Subnet in Availability Zone 1
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_a
}

# Define Private Subnet in Availability Zone 1
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_a_cidr
  availability_zone = var.availability_zone_a
}

# Define Public Subnet in Availability Zone 2
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_b
}

# Define Private Subnet in Availability Zone 2
resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_b_cidr
  availability_zone = var.availability_zone_b
}

resource "aws_subnet" "private_db_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_db_subnet_a_cidr
  availability_zone = var.availability_zone_a
}

resource "aws_subnet" "private_db_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_db_subnet_b_cidr
  availability_zone = var.availability_zone_b 
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.tags.Project}-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
}

# Define Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Define Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Route Table with Public Subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}