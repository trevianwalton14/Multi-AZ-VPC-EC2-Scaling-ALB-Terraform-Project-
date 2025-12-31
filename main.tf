terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
}

resource "aws_vpc" "multi_az_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Multi-AZ VPC"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.multi_az_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.multi_az_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.multi_az_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.multi_az_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.multi_az_vpc.id
  tags = {
    Name = "Multi-AZ IGW"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT EIP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  tags = {
    Name = "Multi-AZ NAT Gateway"
  }
}

resource "aws_route_table" "Public" {
  vpc_id = aws_vpc.multi_az_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.Public.id

}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.Public.id

}
resource "aws_route_table" "Private" {
  vpc_id = aws_vpc.multi_az_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.Private.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.Private.id

}

resource "aws_security_group" "alb_sg" {
  vpc_id                 = aws_vpc.multi_az_vpc.id
  revoke_rules_on_delete = true
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = aws_vpc.multi_az_vpc.cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  depends_on = [aws_security_group.alb_sg]
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_egress" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  depends_on = [aws_security_group.alb_sg]
}

resource "aws_security_group" "app_sg" {
  vpc_id                 = aws_vpc.multi_az_vpc.id
  revoke_rules_on_delete = true
}

resource "aws_vpc_security_group_ingress_rule" "app_sg_ingress" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = aws_vpc.multi_az_vpc.cidr_block
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_sg_egress" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "bastion_sg" {
  vpc_id                 = aws_vpc.multi_az_vpc.id
  revoke_rules_on_delete = true

}

resource "aws_vpc_security_group_ingress_rule" "bastion_sg_ingress" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = aws_vpc.multi_az_vpc.cidr_block
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

}

resource "aws_vpc_security_group_egress_rule" "bastion_sg_egress" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "bastion" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
}

resource "aws_lb" "alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.multi_az_vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_launch_template" "app_template" {
  name = "app-template"

  image_id               = "ami-068c0051b15cdb816"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(<<-EOF
                #!/bin/bash
                sudo yum update -y
                echo "Hello from Terraform EC2 ASG!" > /var/www/html/index.html
                sudo yum install -y httpd 
                sudo systemctl start httpd
                sudo systemctl enable httpd
                EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
}