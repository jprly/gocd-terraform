# resource "aws_ecs_cluster" "ci-container-cluster" {
#   name = "CI-Container-Cluster"
# }
# resource "aws_instance" "ci-container-host-1" {
#   ami           = "ami-0d1c47ab964ae2b87" #ecs optimized image
#   instance_type = "t2.medium"
#   security_groups = [aws_security_group.gocd-sg.name]
# #   vpc_security_group_ids      = ["${aws_security_group.ci-container-host-security-group.id}"]
# #   subnet_id                   = "${element(data.aws_subnet_ids.public_subnets.ids, 0)}"
#   key_name                    = "jenkins23"
#   associate_public_ip_address = true
#   user_data = <<EOF
# #!/bin/bash
# echo ECS_CLUSTER=${aws_ecs_cluster.ci-container-cluster.name} >> /etc/ecs/ecs.config
# echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config
# echo NO_PROXY=169.254.169.254,169.254.170.2,/var/run/docker.sock >> /etc/ecs/ecs.config
# echo 'vm.max_map_count = 262144' >> /etc/sysctl.conf
# sysctl -p
# EOF
#   iam_instance_profile = "${aws_iam_instance_profile.ingest.name}"
#   tags = {
#     Name = "CI-Container-Host-1"
#   }
# }
# data "aws_iam_role" "ecsInstanceRole" {
#   name = "ecsInstanceRole"
# }
# resource "aws_iam_instance_profile" "ingest" {
#   name  = "ingest_profile"
#   role = "${data.aws_iam_role.ecsInstanceRole.name}"
# }

# resource "aws_ecr_repository" "agent-repository" {
#   name = "terraform_agent"
# }
# resource "aws_ecr_repository_policy" "ci-agent-ecr-policy" {
#   repository = "${aws_ecr_repository.agent-repository.name}"
#   policy = <<EOF
# {
#     "Version": "2008-10-17",
#     "Statement": [
#         {
#             "Sid": "new policy",
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": [
#                 "ecr:GetDownloadUrlForLayer",
#                 "ecr:BatchGetImage",
#                 "ecr:BatchCheckLayerAvailability",
#                 "ecr:PutImage",
#                 "ecr:InitiateLayerUpload",
#                 "ecr:UploadLayerPart",
#                 "ecr:CompleteLayerUpload",
#                 "ecr:DescribeRepositories",
#                 "ecr:GetRepositoryPolicy",
#                 "ecr:ListImages",
#                 "ecr:DeleteRepository",
#                 "ecr:BatchDeleteImage",
#                 "ecr:SetRepositoryPolicy",
#                 "ecr:DeleteRepositoryPolicy"
#             ]
#         }
#     ]
# }
# EOF
# }
# resource "aws_ecr_lifecycle_policy" "ci-agent-ecr-policy" {
#   repository = "${aws_ecr_repository.agent-repository.name}"
#   policy = <<EOF
# {
#     "rules": [
#         {
#             "rulePriority": 1,
#             "description": "Keep last 5 images",
#             "selection": {
#                 "tagStatus": "tagged",
#                 "tagPrefixList": ["v"],
#                 "countType": "imageCountMoreThan",
#                 "countNumber": 5
#             },
#             "action": {
#                 "type": "expire"
#             }
#         }
#     ]
# }
# EOF
# }