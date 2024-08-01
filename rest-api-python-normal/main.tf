resource "aws_ecs_cluster" "main" {
  name = "flask-api-cluster"
}

resource "aws_ecs_task_definition" "flask_api" {
  family                   = "flask-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "flask-api"
      image     = "your-dockerhub-username/flask-api:latest"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "flask_api" {
  name            = "flask-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask_api.arn
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.default[*].id
    security_groups = [aws_security_group.flask_api.id]
  }
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default" {
  count             = 2
  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = element(var.availability_zones, count.index)
}

resource "aws_security_group" "flask_api" {
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b"]
}
