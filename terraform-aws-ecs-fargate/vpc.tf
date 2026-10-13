resource "aws_vpc" "django_app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC for django app"
  }
}

data "aws_availability_zones" "available_zone" {
  state = "available"
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = var.public1_cidr
  availability_zone = data.aws_availability_zones.available_zone.names[0]
  tags = {
    Name = "Public subnet 1"
  }

}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = var.public2_cidr
  availability_zone = data.aws_availability_zones.available_zone.names[1]
  tags = {
    Name = "Public subnet 2"
  }

}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = var.private1_cidr
  availability_zone = data.aws_availability_zones.available_zone.names[0]
  tags = {
    Name = "Private subnet 1"
  }

}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = var.private2_cidr
  availability_zone = data.aws_availability_zones.available_zone.names[1]
  tags = {
    Name = "Private subnet 2"
  }

}

resource "aws_internet_gateway" "djangoapp_igw" {
  vpc_id = aws_vpc.django_app_vpc.id
  tags = {
    Name = "Internet gateway for djangoapp"
  }
}

resource "aws_eip" "nat_gateway1" {
  domain = "vpc"
}

# Fargate tasks live in private subnets and need NAT to pull the image
# from ECR, read SSM parameters and ship logs to CloudWatch
resource "aws_nat_gateway" "djangoapp_gateway1" {
  allocation_id = aws_eip.nat_gateway1.id
  subnet_id     = aws_subnet.public1.id
  tags = {
    Name = "NAT Gateway 1"
  }
  depends_on = [aws_internet_gateway.djangoapp_igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.django_app_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.djangoapp_gateway1.id
  }
}

resource "aws_route_table_association" "private1_rt_association" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private2_rt_association" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.django_app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.djangoapp_igw.id
  }
}

resource "aws_route_table_association" "public1_rt_association" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public2_rt_association" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

