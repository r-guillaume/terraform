data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["PUBLIC_SUBNET"]
  }
}

data "aws_subnet" "private-a" {
  filter {
    name   = "tag:Name"
    values = ["PRIVATE_SUBNET_A"]
  }
}

data "aws_subnet" "private-b" {
  filter {
    name   = "tag:Name"
    values = ["PRIVATE_SUBNET_B"]
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
  subnet_id              = data.aws_subnet.private-a.id
  availability_zone      = data.aws_availability_zones.available.names[0]
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.ec2.id

  tags = { Name = upper("${var.identifiant}_VM") }
}

resource "aws_key_pair" "ec2" {
   key_name   = lower("${var.identifiant}_key")
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdgUoVRIPCQHlBoaz6UfrvQ4gw2sxeV3PIgCmCSXUW+I9beSfrBs4ELbiuUsV33Y8rKRNQBxa60+J0bEwNtIXRARN7bfdVmukoIJ/LBPcj1XzjmcVE4RJCxSRQbiMYnbUG6Ps5m1sMXsGf0WoPuXIsYoRKHa4QtcqSqqm/G/BW4a0Kvwdfww2dYCKhNoniSPAnDGPowQpGzTc3nvO/ED7polY9T1b6kqaw5WSCWic/qUfgJ2Lxn+bus72vgelhqZhFSqJgTL2e3xPmqtmrUO/4U2kjF3YH120syEfvQFIg/PozQqfkupbDPB1Cx7/1ThZLpJT5Dv1I/kCuZQuNNZj7"
}


resource "aws_db_subnet_group" "default" {
  name       = lower("${var.identifiant}_SUBNET_GROUP_RDS")
  subnet_ids = [data.aws_subnet.private-a.id, data.aws_subnet.private-b.id]

  tags = {
    Name = "${var.identifiant}_SUBNET_GROUP_RDS"
  }
}