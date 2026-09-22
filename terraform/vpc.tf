resource "aws_vpc" "django_app_vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "VPC for django app"
  }
}

data "aws_availability_zones" "available_zone" {
  state = "available"
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = data.aws_availability_zones.available_zone.names[0]
  tags = {
    Name = "Public subnet 1"
  }

}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = "10.1.20.0/24"
  availability_zone = data.aws_availability_zones.available_zone.names[1]
  tags = {
    Name = "Public subnet 2"
  }

}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = "10.1.50.0/24"
  availability_zone = data.aws_availability_zones.available_zone.names[0]
  tags = {
    Name = "Private subnet 1"
  }

}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.django_app_vpc.id
  cidr_block        = "10.1.60.0/24"
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




resource "aws_security_group" "alb_sg" {
  name        = "djangoapp-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.django_app_vpc.id

  # ingress {

  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "db_sg" {
  name        = "ec2_db_sg"
  description = "Security group for ec2 instance with DB"
  vpc_id      = aws_vpc.django_app_vpc.id

  # ingress {

  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "app_instance_sg" {
  name        = "app_instance-sg"
  description = "Security group for ec2 app instance"
  vpc_id      = aws_vpc.django_app_vpc.id

  # ingress {

  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
