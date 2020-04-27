# --------------------------------------------
# Provider and credentials
# --------------------------------------------
provider "aws" {
  version = "~> 2.0"
  region = var.region
  secret_key = var.secret-key
  access_key = var.access-key
}

# --------------------------------------------
# Uploas SSH key-pair
# --------------------------------------------
resource "aws_key_pair" "public-key" {
  key_name = "cqt"
  public_key = var.public-key
}

# --------------------------------------------
# Public security group
# --------------------------------------------
resource "aws_security_group" "instance-public" {
  name = "cqt-public"
  description = "ssh-only"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------------------
# Machine(s)
# --------------------------------------------
resource "aws_instance" "ec2-instance" {
  count = var.instances-number
  ami  = var.instance-ami
  instance_type = var.instance-type
  key_name = aws_key_pair.public-key.key_name
  source_dest_check = false
  associate_public_ip_address = true
  security_groups = [aws_security_group.instance-public.name]

  tags = {
    Name = "ec2-instance"
  }
}

output "Instances-Public-Ip" {
  value = aws_instance.ec2-instance.*.public_ip
}
