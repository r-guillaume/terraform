data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["PUBLIC_SUBNET"]
  }
}

data "aws_subnet" "private" {
  filter {
    name   = "tag:Name"
    values = ["PRIVATE_SUBNET"]
  }
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["VPC"]
  }
}

data "aws_security_group" "bastion" {
  filter {
    name   = "tag:Name"
    values = ["SG_BASTION_EC2"]
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.identifiant}_SG_EC2"
  description = "ec2 Security Group"
  vpc_id      = data.aws_vpc.selected.id
  tags        = { Name = "${var.identifiant}_SG_EC2" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_ec2_to_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.bastion.id
  security_group_id        = aws_security_group.ec2.id
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = data.aws_subnet.private.id
  availability_zone      = data.aws_availability_zones.available.names[0]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]

  tags = { Name = upper("${var.identifiant}_VM") }
}
