# Security Group
variable "ingressports" {
  type    = list(number)
  default = [8080, 22, 8153]
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

resource "aws_instance" "gocd" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = "t2.medium"
  security_groups = [aws_security_group.gocd-sg.name]
  key_name        = "jenkins23"
  provisioner "remote-exec" {
    inline = [
      "sudo yum update –y",
      "sudo curl https://download.gocd.org/gocd.repo -o /etc/yum.repos.d/gocd.repo",
      "sudo yum install git -y",
      "sudo yum install -y go-server",
      "sudo yum install -y go-agent",
      "sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash",
      ". ~/.nvm/nvm.sh",
      "sudo source ~/.bashrc",
      "sudo nvm install 16",
      "sudo service go-server start",
      "sudo service go-agent start"
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = data.aws_ssm_parameter.jenkins_pem.value
  }
  tags = {
    "Name" = "GoCD"
  }
}


data "aws_ssm_parameter" "jenkins_pem" {
  name = "/secure/inf/jenkins_pem"
}
