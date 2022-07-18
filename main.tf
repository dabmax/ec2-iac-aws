terraform {
  required_providers {
    aws = {
        source  = "registry.terraform.io/hashicorp/aws"
        version = ">=1.0.0"
    }
  }
}

resource "aws_vpc" "vpc-nginx-ton" {
  cidr_block              = var.ton-network-address
  enable_dns_support      = "true"
  enable_dns_hostnames    = "true"
  enable_classiclink      = "false"
  instance_tenancy        = "default"
}

resource "aws_subnet" "prod-subnet-public-ton-1" {
  vpc_id                    = aws_vpc.vpc-nginx-ton.id
  cidr_block                = var.ton-network-address
  map_public_ip_on_launch   = "true"
  availability_zone         = var.ton-rz
}

resource "aws_internet_gateway" "prod-igw-ton" {
  vpc_id = aws_vpc.vpc-nginx-ton.id
}

resource "aws_route_table" "prod-public-ton-crt" {
  vpc_id = aws_vpc.vpc-nginx-ton.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.prod-igw-ton.id
  }
tags = {
    name = "prod-public-ton-crt"
    }
}

resource "aws_route_table_association" "prod-crta-public-subnet-ton-1" {
  subnet_id         = aws_subnet.prod-subnet-public-ton-1.id
  route_table_id    = aws_route_table.prod-public-ton-crt.id
}

resource "aws_security_group" "ssh-http-allowed" {
  vpc_id    = aws_vpc.vpc-nginx-ton.id
  egress {
      from_port     = 0
      to_port       = 0
      protocol      = -1
      cidr_blocks    = ["0.0.0.0/0"]
  }
  ingress {
      from_port     = var.port-ssh
      to_port       = var.port-ssh
      protocol      = "tcp"
      cidr_blocks    = var.trusted-address
  }
  ingress {
      from_port     = var.port-https
      to_port       = var.port-https
      protocol      = "tcp"
      cidr_blocks    = ["0.0.0.0/0"]
  }
}

#### Add key SSH ####
resource "aws_key_pair" "aws-key-ton" {
  key_name      = "aws-key"
  public_key    = file("${var.ssh-key}")
}

#### Block creating EC2 Instance #####

resource "aws_instance" "srv-nginx-ton" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = var.instance-group

tags = {
    name = "srv-nginx-ton"
}

  subnet_id = aws_subnet.prod-subnet-public-ton-1.id
  vpc_security_group_ids = ["${aws_security_group.ssh-http-allowed.id}"]
  key_name = aws_key_pair.aws-key-ton.id
  
  provisioner "file" {
    source      = "nginx.sh"
    destination = "/tmp/nginx.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nginx.sh",
      "sudo /tmp/nginx.sh"
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${var.ssh-key}")
  }
}

