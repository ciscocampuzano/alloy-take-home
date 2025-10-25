# ECS Cluster Module
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 6.6.2"

  name = "${local.resource_prefix}-cluster"

  tags = {
    Name        = "${local.resource_prefix}-cluster"
    Environment = local.environment
  }
}

# ECS Service Module
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.6.2"

  name        = "${local.resource_prefix}-service"
  cluster_arn = module.ecs_cluster.arn

  # Fargate launch type
  launch_type = "FARGATE"

  cpu    = local.container_cpu
  memory = local.container_memory

  # Container definition
  container_definitions = {
    (local.resource_prefix) = {
      image     = local.container_image
      essential = true

      portMappings = [
        {
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = local.aws_region
        },
        {
          name  = "S3_BUCKET_NAME"
          value = module.s3_bucket.s3_bucket_id
        }
      ]

      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      readonly_root_filesystem = true

      log_configuration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = local.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      mountPoints = [
        {
          sourceVolume  = "nginx_cache"
          containerPath = "/var/cache/nginx"
          readOnly      = false
        },
        {
          sourceVolume  = "nginx_run"
          containerPath = "/var/run"
          readOnly      = false
        },
        {
          sourceVolume  = "app_data"
          containerPath = "/tmp/nginx-html"
          readOnly      = false
        }
      ]
    }
  }

  # Volume definitions for writable directories
  volume = {
    nginx_cache = {}
    nginx_run   = {}
    app_data    = {}
  }

  # IAM roles
  task_exec_iam_role_arn = aws_iam_role.ecs_task_execution_role.arn
  tasks_iam_role_arn     = aws_iam_role.ecs_task_role.arn

  # Disable ECS service module IAM role creation (we provide our own)
  create_task_exec_iam_role = false
  create_tasks_iam_role     = false

  # Networking
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.ecs_tasks_sg.security_group_id]

  # Load balancer
  load_balancer = {
    service = {
      target_group_arn = element([for tg in module.alb.target_groups : tg.arn], 0)
      container_name   = local.resource_prefix
      container_port   = local.container_port
    }
  }

  # Desired count
  desired_count = local.desired_count

  # Auto-scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 10

  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 70.0
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        target_value = 80.0
      }
    }
  }

  tags = {
    Name        = "${local.resource_prefix}-service"
    Environment = local.environment
  }
}

# Application Load Balancer Module
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0.2"

  name = "${local.resource_prefix}-alb"

  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  enable_deletion_protection = false

  # Target groups
  target_groups = {
    ecs = {
      name_prefix      = "ecs-"
      backend_protocol = "HTTP"
      backend_port     = local.container_port
      target_type      = "ip"

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }

  # Listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ecs"
      }
    }
  }

  tags = {
    Name        = "${local.resource_prefix}-alb"
    Environment = local.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${local.resource_prefix}"
  retention_in_days = 30

  tags = {
    Name = "${local.resource_prefix}-ecs-logs"
  }
}
