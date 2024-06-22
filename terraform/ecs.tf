resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-ecs-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-ecs-task"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn

  container_definitions = jsonencode(
    [
      {
        name      = var.container_name
        image     = var.image
        essential = true
        cpu       = 256
        # command   = ["/usr/bin/env"]
        "logConfiguration" = {
          "logDriver" = "awslogs"
          "options" = {
            "awslogs-group"         = aws_cloudwatch_log_group.this.name
            "awslogs-stream-prefix" = aws_cloudwatch_log_stream.this.name
            "awslogs-region"        = var.aws_region
          }
        }
        portMappings = [
          {
            protocol      = "tcp"
            containerPort = 80
          }
        ]
      }
    ]
  )
}

resource "aws_ecs_service" "this" {
  name                              = "${var.prefix}-ecs-service"
  cluster                           = aws_ecs_cluster.this.arn
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets = [
      aws_subnet.public["public-1a"].id,
      aws_subnet.public["public-1b"].id
    ]
    security_groups  = [module.nginx_sg.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.http.arn
    container_name   = var.container_name
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.prefix}-ecs-log-group"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${var.prefix}-ecs-log-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}

data "aws_iam_policy" "ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_policy_documents = [
  data.aws_iam_policy.ecs_task_execution_role.policy]

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = [aws_cloudwatch_log_group.this.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ssm:GetParameters",
      "km:Decrypt"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}
