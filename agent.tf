locals {
    agent_image = "434569203303.dkr.ecr.us-east-2.amazonaws.com/jprly:latest"
}

resource "aws_ecs_cluster" "gocd_agent" {
  name = "gocd-agent"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.gocd_agent.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_service" "gocd" {
  name    = "gocd-agent-service"
  launch_type = "FARGATE"
  desired_count   = 2
  network_configuration {
    assign_public_ip = true
    subnets = [for subnet in local.availability_zones : aws_default_subnet.az[subnet].id]

  }
  cluster = aws_ecs_cluster.gocd_agent.id
  task_definition = aws_ecs_task_definition.gocd_agent.arn

}

resource "aws_ecs_task_definition" "gocd_agent" {
  family = "gocd-agent"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
  execution_role_arn = "arn:aws:iam::434569203303:role/ecsTaskExecutionRole"
  container_definitions = jsonencode([
    {
      name      = "agent"
      image     = "${local.agent_image}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol = "tcp"
          appProtocol = "http"
          name = "gocd-tcp"
        }
      ]
      environment = [
        {"name": "GO_SERVER_URL", "value": "http://${aws_lb.gocd.dns_name}/go"}
      ],
    }
  ])
}