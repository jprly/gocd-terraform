# Security Group
variable "ingressports" {
  type    = list(number)
  default = [80, 8080, 22, 8153]
}

resource "aws_security_group" "gocd-sg" {
  name        = "Allow GoCD traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {
    for_each = var.ingressports
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name"      = "gocd-sg"
    "Terraform" = "true"
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

  owners = ["amazon"]

}

data "aws_ssm_parameter" "gocd_config" {
  name = "/secure/inf/gocd/config"
}

resource "aws_instance" "gocd" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.gocd-sg.name]
  key_name        = "jenkins23"
  user_data       = <<EOF
#!/bin/bash
sudo yum update –y
sudo curl https://download.gocd.org/gocd.repo -o /etc/yum.repos.d/gocd.repo
sudo yum install git -y
sudo yum install -y go-server
sudo source ~/.bashrc
sudo cat  /etc/go/cruise-config.xml | grep -oP 'agentAutoRegisterKey="\K[^"]+'
sudo service go-server start
EOF

  tags = {
    "Name" = "GoCD"
  }
}


data "aws_ssm_parameter" "jenkins_pem" {
  name = "/secure/inf/jenkins_pem"
}
