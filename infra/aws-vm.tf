data "aws_ami" "al2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "multicloud_lab_vm_sg" {
  name        = "multicloud-lab-vm-sg"
  description = "Security group for the multicloud lab VM."
  vpc_id      = aws_vpc.multicloud_lab_vpc.id

  tags = {
    Name = "multicloud-lab-vm-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.multicloud_lab_vm_sg.id

  referenced_security_group_id = aws_security_group.multicloud_lab_eice_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22

  tags = {
    Name = "from_eice_allow_ssh"
  }
}

resource "aws_security_group" "multicloud_lab_eice_sg" {
  name        = "multicloud-lab-eice-sg"
  description = "Security group for the multicloud lab EICE."
  vpc_id      = aws_vpc.multicloud_lab_vpc.id

  tags = {
    Name = "multicloud-lab-eice-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_ssh" {
  security_group_id = aws_security_group.multicloud_lab_eice_sg.id

  referenced_security_group_id = aws_security_group.multicloud_lab_vm_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22

  tags = {
    Name = "to_vm_allow_ssh"
  }
}

resource "aws_ec2_instance_connect_endpoint" "multicloud_lab_eice" {
  subnet_id = aws_subnet.private_subnet.id

  preserve_client_ip = false

  security_group_ids = [aws_security_group.multicloud_lab_eice_sg.id]

  tags = {
    Name = "multicloud-lab-eice"
  }
}

resource "aws_instance" "multicloud_lab_vm" {
  ami                    = data.aws_ami.al2023_arm64.id
  instance_type          = "t4g.nano"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.multicloud_lab_vm_sg.id]
  private_ip             = "10.10.0.10"

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "multicloud-lab-vm"
  }
}