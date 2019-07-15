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
resource "aws_key_pair" "cq-test-key" {
  key_name = "cqt"
  public_key = var.public-key
}

# --------------------------------------------
# VPC
# --------------------------------------------
resource "aws_vpc" "cqt-cassandra" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "cqt-cassandra"
  }
}

# --------------------------------------------
# Public subnet
# --------------------------------------------
resource "aws_subnet" "cqt-cassandra-public" {
  vpc_id = aws_vpc.cqt-cassandra.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "cqt-cassandra Public Subnet"
  }
}

# --------------------------------------------
# Private subnet
# --------------------------------------------
resource "aws_subnet" "cqt-cassandra-private" {
  vpc_id = aws_vpc.cqt-cassandra.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Cassandra Private Subnet"
  }
}

# --------------------------------------------
# IGW
# --------------------------------------------
resource "aws_internet_gateway" "cqt-cassandra" {
  vpc_id = aws_vpc.cqt-cassandra.id

  tags = {
    Name = "cqt-cassandra"
  }
}

# --------------------------------------------
# Routing table
# --------------------------------------------
resource "aws_route_table" "cqt-cassandra" {
  vpc_id = aws_vpc.cqt-cassandra.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cqt-cassandra.id
  }

  tags = {
    Name = "cqt-cassandra-public"
  }
}

# --------------------------------------------
# Connect route table to public subnet
# --------------------------------------------
resource "aws_route_table_association" "cqt-cassandra-public" {
  subnet_id = aws_subnet.cqt-cassandra-public.id
  route_table_id = aws_route_table.cqt-cassandra.id
}

# --------------------------------------------
# Connect route table to private subnet
# --------------------------------------------
resource "aws_route_table_association" "cqt-cassandra-private" {
  subnet_id = aws_subnet.cqt-cassandra-private.id
  route_table_id = aws_route_table.cqt-cassandra.id
}

# --------------------------------------------
# Public security group
# --------------------------------------------
resource "aws_security_group" "cqt-cassandra-public" {
  name = "cqt-cassandra-public"
  description = "ssh-only"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  # salt minion ports
  ingress {
    from_port = 4505
    to_port = 4506
    protocol = "tcp"
    cidr_blocks =  ["10.0.2.0/24"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id=aws_vpc.cqt-cassandra.id
}

# --------------------------------------------
# Private security group
# --------------------------------------------
resource "aws_security_group" "cqt-cassandra-private"{
  name = "cqt-cassandra-private"
  description = "Allow traffic from public subnet"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks =  ["10.0.1.0/24"]
  }

  # allow intercomunication
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks =  ["10.0.2.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.cqt-cassandra.id
}

variable "number" {
  default = 2
}

# --------------------------------------------
# Salt master template file
# --------------------------------------------
data "template_file" "salt-master" {
  template = file("provision/user-data/salt-master.sh")
}

# --------------------------------------------
# Bastion machine
# --------------------------------------------
resource "aws_instance" "provision" {
  ami  = var.instance-ami
  instance_type = var.instance-type
  key_name = aws_key_pair.cq-test-key.key_name
  subnet_id = aws_subnet.cqt-cassandra-public.id
  vpc_security_group_ids = [aws_security_group.cqt-cassandra-public.id]
  associate_public_ip_address = true
  source_dest_check = false
  user_data = data.template_file.salt-master.rendered

  tags = {
    Name = "provision"
  }

  connection {
    user = "ubuntu"
    host = aws_instance.provision.public_ip
    port = 22
    private_key = file(var.private-key)
  }

  provisioner "remote-exec" {
    inline = [
      # install salt master and start it
      "curl -L https://bootstrap.saltstack.com -o install_salt.sh",
      "sudo sh install_salt.sh -P -M -N",

      # start minion with specific id
      "sudo sh install_salt.sh -P -i provision",
    ]
  }

  provisioner "file" {
    source = "./provision/upload"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/upload/install.sh"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ./tmp/provision-ip"
  }

  provisioner "local-exec" {
    when = "destroy"
    command = "rm -r ./tmp/provision-ip"
  }
}

output "Bastion-Public-Ip" {
  value = aws_instance.provision.*.public_ip
}

# --------------------------------------------
# Salt cassandra-seed template file
# --------------------------------------------
data "template_file" "cassandra-seed" {
  count = var.seed-number
  template = file("cassandra/user-data/salt-minion.sh")
  vars = {
    master_private_ip = aws_instance.provision.private_ip
    name = "cassandra-seed"
    index = count.index
  }
}

# --------------------------------------------
# Storage seed machine(s)
# --------------------------------------------
resource "aws_instance" "cassandra-seed" {
  count = var.seed-number
  ami  = var.instance-ami
  instance_type = var.instance-type
  key_name = aws_key_pair.cq-test-key.key_name
  subnet_id = aws_subnet.cqt-cassandra-private.id
  vpc_security_group_ids = [aws_security_group.cqt-cassandra-private.id]
  source_dest_check = false
  associate_public_ip_address = true
  user_data = data.template_file.cassandra-seed[count.index].rendered

  tags = {
    Name = "Cassandra-Seed"
  }
}

output "Cassandra-Seed-Private-Ip" {
  value = aws_instance.cassandra-seed.*.private_ip
}

# --------------------------------------------
# Salt cassandra-node template file
# --------------------------------------------
data "template_file" "cassandra-node" {
  count = var.node-number
  template = file("cassandra/user-data/salt-minion.sh")
  vars = {
    master_private_ip = aws_instance.provision.private_ip
    name = "cassandra-node"
    index = count.index
  }
}

# --------------------------------------------
# Storage node machine(s)
# --------------------------------------------
resource "aws_instance" "cassandra-node" {
  count = var.node-number
  ami  = var.instance-ami
  instance_type = var.instance-type
  key_name = aws_key_pair.cq-test-key.key_name
  subnet_id = aws_subnet.cqt-cassandra-private.id
  vpc_security_group_ids = [aws_security_group.cqt-cassandra-private.id]
  source_dest_check = false
  associate_public_ip_address = true
  user_data = data.template_file.cassandra-node[count.index].rendered

  tags = {
    Name = "Cassandra-Node"
  }
}

output "Cassandra-Node-Private-Ip" {
  value = aws_instance.cassandra-node.*.private_ip
}

# --------------------------------------------
# Count resourced
# --------------------------------------------
resource "null_resource" "packer" {
  triggers = {
    build_number = timestamp()
  }
  provisioner "local-exec" {
    # first 1 is provission machine
    command = "echo $((1 + ${var.node-number} + ${var.seed-number})) > ./tmp/count-resources"
  }

  # upload resources number to salt master
  provisioner "local-exec" {
    command = "scp -r -o \"StrictHostKeyChecking no\" ./tmp/count-resources ubuntu@$(cat tmp/provision-ip):/tmp"
  }
}
