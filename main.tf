provider "aws" {
  region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable "my_ip" {}
variable "instance_size" {}
variable "pub_location" {}
variable "private_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-internet-gateway.id
  }
  tags = {
    Name: "${var.env_prefix}-route-table"
  }
}

resource "aws_internet_gateway" "myapp-internet-gateway" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name : "${var.env_prefix}-internet-gateway"
  }
}

resource "aws_route_table_association" "myapp-route-table-association" {
  route_table_id = aws_route_table.myapp-route-table.id
  subnet_id = aws_subnet.myapp-subnet-1.id
}

resource "aws_security_group" "myapp-securityGroup" {
  name = "myapp-securityGroup"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name : "${var.env_prefix}-securityGroup"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# output "test_ami" {
#   value = data.aws_ami.latest-amazon-linux-image
# }

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.pub_location)
}


resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_size

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-securityGroup.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  #   user_data = <<EOF
  # #!/bin/bash
  # sudo yum update -y && sudo yum install -y docker
  # sudo systemctl start docker
  # sudo usermod -aG docker ec2-user
  # docker run -p 8080:80 nginx
  # EOF

  # user_data = file("entry-script.sh")
  user_data_replace_on_change = true


  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source = "entry-script.sh"
    destination = "home/ec2-user/entry-script.sh"
    # usual cp / mv files on linux apply, but don't forget you'll need to change the execution script name too (obvs)
  }

  provisioner "local-exec" {
      command = "echo ${self.public_ip} > ec2-Public-ip.txt"
  }


#   provisioner "remote-exec" {
#     inline = [
#       "home/ec2-user/entry-script.sh"
#       #"export ENV=dev",
#       #"mkdir newdir",
#       #"sudo yum docker"
#       # etc
#     ]
#   }



  tags = {
    Name: "${var.env_prefix}-ec2"
  }
}