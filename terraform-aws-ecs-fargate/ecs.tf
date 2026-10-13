resource "aws_cloudwatch_log_group" "djangoapp" {
  name              = "/ecs/djangoapp"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "djangoapp" {
  name = "djangoapp-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "djangoapp-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "read_app_params" {
  name = "ecs-read-app-params-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
        ]
        Effect = "Allow"
        Resource = [
          aws_ssm_parameter.djangoapp_db_password.arn,
          aws_ssm_parameter.django_secret_key.arn,
      ] },
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "djangoapp-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_ecr_repository" "djangoapp" {
  name = var.ecr_repository_name
}


resource "aws_ecs_task_definition" "djangoapp" {
  family                   = "djangoapp"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = "djangoapp"
      image     = "${data.aws_ecr_repository.djangoapp.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        },
      ]

      environment = [
        { name = "DB", value = "postgres" },
        { name = "DB_HOST", value = aws_db_instance.djangoapp_db.address },
        { name = "DB_PORT", value = tostring(aws_db_instance.djangoapp_db.port) },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_SSLMODE", value = "require" },
        { name = "DEBUG", value = "False" },
        { name = "SITE_ROOT", value = "http://${aws_lb.djangoapp_lb.dns_name}" },
        { name = "ALLOWED_HOSTS", value = "*" },
      ]

      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.djangoapp_db_password.arn },
        { name = "SECRET_KEY", valueFrom = aws_ssm_parameter.django_secret_key.arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.djangoapp.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    },
  ])
}

resource "aws_ecs_service" "djangoapp" {
  name            = "djangoapp-service"
  cluster         = aws_ecs_cluster.djangoapp.id
  task_definition = aws_ecs_task_definition.djangoapp.arn
  desired_count   = 1
  launch_type     = "FARGATE"
#   enable_execute_command = true

  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.djangoapp_tg.arn
    container_name   = "djangoapp"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.djangoapp_listener,
    aws_iam_role_policy_attachment.ecs_task_execution_attach,
    aws_iam_role_policy.read_app_params,
    aws_route_table_association.private1_rt_association,
    aws_route_table_association.private2_rt_association,
  ]
}
