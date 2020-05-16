// IAM
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}

module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}

// S3
resource "aws_s3_bucket" "private" {
  bucket = "private-rails-form-training"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-rails-form-training"
  acl    = "public-read"

  cors_rule {
    allowed_origins = ["https://matsushin11.net"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-rails-form-training"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

// VPC
resource "aws_vpc" "rails-form-training" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "rails-form-training"
  }
}

resource "aws_internet_gateway" "rails-form-training" {
  vpc_id = aws_vpc.rails-form-training.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rails-form-training.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.rails-form-training.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.rails-form-training.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.rails-form-training.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.rails-form-training.id
  cidr_block              = "10.0.65.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.rails-form-training.id
  cidr_block              = "10.0.66.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"
}

resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.rails-form-training]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.rails-form-training]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.rails-form-training]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.rails-form-training]
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.rails-form-training.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.rails-form-training.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

// security group
module "example_sg" {
  source      = "./security_group"
  name        = "rails-form-training-module-sg"
  vpc_id      = aws_vpc.rails-form-training.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

// Load Balancer
resource "aws_lb" "rails-form-training" {
  name                       = "rails-form-training"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

output "alb_dns_name" {
  value = aws_lb.rails-form-training.dns_name
}

module "http_sg" {
  source      = "./security_group"
  name        = "rails-form-training-http-sg"
  vpc_id      = aws_vpc.rails-form-training.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "rails-form-training-https-sg"
  vpc_id      = aws_vpc.rails-form-training.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "rails-form-training-http-redirect-sg"
  vpc_id      = aws_vpc.rails-form-training.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.rails-form-training.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.rails-form-training.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.rails-form-training.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTPS」です"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.rails-form-training.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// Route 53
data "aws_route53_zone" "rails-form-training" {
  name = "matsushin11.net"
}

resource "aws_route53_zone" "test_rails-form-training" {
  name = "test.matsushin11.net"
}

resource "aws_route53_record" "rails-form-training" {
  zone_id = data.aws_route53_zone.rails-form-training.zone_id
  name    = data.aws_route53_zone.rails-form-training.name
  type    = "A"

  alias {
    name                   = aws_lb.rails-form-training.dns_name
    zone_id                = aws_lb.rails-form-training.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.rails-form-training.name
}

// ACM
resource "aws_acm_certificate" "rails-form-training" {
  domain_name               = aws_route53_record.rails-form-training.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "rails-form-training_certificate" {
  name    = aws_acm_certificate.rails-form-training.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.rails-form-training.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.rails-form-training.domain_validation_options[0].resource_record_value]
  zone_id = data.aws_route53_zone.rails-form-training.id
  ttl     = 60
}

resource "aws_acm_certificate_validation" "rails-form-training" {
  certificate_arn         = aws_acm_certificate.rails-form-training.arn
  validation_record_fqdns = [aws_route53_record.rails-form-training_certificate.fqdn]
}

resource "aws_lb_target_group" "rails-form-training" {
  name                 = "rails-form-training"
  target_type          = "ip"
  vpc_id               = aws_vpc.rails-form-training.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.rails-form-training]
}

resource "aws_lb_listener_rule" "rails-form-training" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rails-form-training.arn
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

// ECS
resource "aws_ecs_cluster" "rails-form-training" {
  name = "rails-form-training"
}

resource "aws_ecs_task_definition" "rails-form-training" {
  family                   = "rails-form-training"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

resource "aws_ecs_service" "rails-form-training" {
  name                              = "rails-form-training"
  cluster                           = aws_ecs_cluster.rails-form-training.arn
  task_definition                   = aws_ecs_task_definition.rails-form-training.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rails-form-training.arn
    container_name   = "rails-form-training"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "rails-form-training-nginx-sg"
  vpc_id      = aws_vpc.rails-form-training.id
  port        = 80
  cidr_blocks = [aws_vpc.rails-form-training.cidr_block]
}

resource "aws_ecs_task_definition" "rails-form-training_batch" {
  family                   = "rails-form-training-batch"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./batch_container_definitions.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

// CloudWatch Logs
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/rails-form-training"
  retention_in_days = 180
}

resource "aws_cloudwatch_event_target" "rails-form-training_batch" {
  target_id = "rails-form-training-batch"
  rule      = aws_cloudwatch_event_rule.rails-form-training_batch.name
  role_arn  = module.ecs_events_role.iam_role_arn
  arn       = aws_ecs_cluster.rails-form-training.arn

  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    platform_version    = "1.3.0"
    task_definition_arn = aws_ecs_task_definition.rails-form-training_batch.arn

    network_configuration {
      assign_public_ip = "false"
      subnets          = [aws_subnet.private_0.id]
    }
  }
}

resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name              = "/ecs-scheduled-tasks/rails-form-training"
  retention_in_days = 180
}

module "ecs_events_role" {
  source     = "./iam_role"
  name       = "ecs-events"
  identifier = "events.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_events_role_policy.policy
}

data "aws_iam_policy" "ecs_events_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

resource "aws_cloudwatch_event_rule" "rails-form-training_batch" {
  name                = "rails-form-training-batch"
  description         = "とても重要なバッチ処理です"
  schedule_expression = "cron(*/2 * * * ? *)"
}

// KMS/SSM
resource "aws_kms_key" "rails-form-training" {
  description             = "RailsFormTraining Customer Master Key"
  enable_key_rotation     = true
  is_enabled              = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "rails-form-training" {
  name          = "alias/rails-form-training"
  target_key_id = aws_kms_key.rails-form-training.key_id
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/db/username"
  value       = "root"
  type        = "String"
  description = "データベースのユーザー名"
}

resource "aws_ssm_parameter" "db_raw_password" {
  name        = "/db/raw_password"
  value       = "VeryStrongPassword!"
  type        = "SecureString"
  description = "データベースのパスワード"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/db/password"
  value       = "uninitialized"
  type        = "SecureString"
  description = "データベースのパスワード"

  lifecycle {
    ignore_changes = [value]
  }
}

// RDS
resource "aws_db_parameter_group" "rails-form-training" {
  name   = "rails-form-training"
  family = "mysql5.7"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

resource "aws_db_option_group" "rails-form-training" {
  name                 = "rails-form-training"
  engine_name          = "mysql"
  major_engine_version = "5.7"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
}

resource "aws_db_subnet_group" "rails-form-training" {
  name       = "rails-form-training"
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]
}

resource "aws_db_instance" "rails-form-training" {
  identifier                 = "rails-form-training"
  engine                     = "mysql"
  engine_version             = "5.7.25"
  instance_class             = "db.t3.small"
  allocated_storage          = 20
  max_allocated_storage      = 100
  storage_type               = "gp2"
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.rails-form-training.arn
  username                   = "admin"
  password                   = "VeryStrongPassword!"
  multi_az                   = true
  publicly_accessible        = false
  backup_retention_period    = 30
  maintenance_window         = "mon:10:10-mon:10:40"
  auto_minor_version_upgrade = false
  deletion_protection        = false
  skip_final_snapshot        = false
  port                       = 3306
  apply_immediately          = false
  vpc_security_group_ids     = [module.mysql_sg.security_group_id]
  parameter_group_name       = aws_db_parameter_group.rails-form-training.name
  option_group_name          = aws_db_option_group.rails-form-training.name
  db_subnet_group_name       = aws_db_subnet_group.rails-form-training.name

  lifecycle {
    ignore_changes = [password]
  }
}

module "mysql_sg" {
  source      = "./security_group/"
  name        = "rails-form-training-mysql-sg"
  vpc_id      = aws_vpc.rails-form-training.id
  port        = 3306
  cidr_blocks = [aws_vpc.rails-form-training.cidr_block]
}

// ECR
resource "aws_ecr_repository" "rails-form-training" {
  name = "rails-form-training"
}

resource "aws_ecr_lifecycle_policy" "rails-form-training" {
  repository = aws_ecr_repository.rails-form-training.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["release"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
EOF
}

// CodeBuild
data "aws_iam_policy_document" "codebuild" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
  }
}

module "codebuild_role" {
  source     = "./iam_role"
  name       = "codebuild"
  identifier = "codebuild.amazonaws.com"
  policy     = data.aws_iam_policy_document.codebuild.json
}

resource "aws_codebuild_project" "rails-form-training" {
  name         = "rails-form-training"
  service_role = module.codebuild_role.iam_role_arn

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    privileged_mode = true
  }
}

// CodePipeline
data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}

module "codepipeline_role" {
  source     = "./iam_role"
  name       = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_s3_bucket" "artifact" {
  bucket = "artifact-rails-form-training"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_codepipeline" "rails-form-training" {
  name     = "rails-form-training"
  role_arn = module.codepipeline_role.iam_role_arn

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      output_artifacts = ["Source"]

      configuration = {
        Owner                = "medakarb"
        Repo                 = "rails-form-training"
        Branch               = "test-terraform"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.rails-form-training.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = 1
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = aws_ecs_cluster.rails-form-training.name
        ServiceName = aws_ecs_service.rails-form-training.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}

resource "aws_codepipeline_webhook" "rails-form-training" {
  name            = "rails-form-training"
  target_pipeline = aws_codepipeline.rails-form-training.name
  target_action   = "Source"
  authentication  = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = "VeryRandomStringMoreThan20Byte!"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

provider "github" {
  organization = "medakarb"
}

resource "github_repository_webhook" "rails-form-training" {
  repository = "rails-form-training"

  configuration {
    url          = aws_codepipeline_webhook.rails-form-training.url
    secret       = "VeryRandomStringMoreThan20Byte!"
    content_type = "json"
    insecure_ssl = false
  }

  events = ["push"]
}

// SSHレスオペレーション
data "aws_iam_policy_document" "ec2_for_ssm" {
  source_json = data.aws_iam_policy.ec2_for_ssm.policy

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "kms:Decrypt",
    ]
  }
}

data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

module "ec2_for_ssm_role" {
  source     = "./iam_role"
  name       = "ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}

resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  role = module.ec2_for_ssm_role.iam_role_name
}

resource "aws_instance" "rails-form-training_for_operation" {
  ami                  = "ami-0c3fd0f5d33134a76"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name
  subnet_id            = aws_subnet.private_0.id
  user_data            = file("./user_data.sh")
}

output "operation_instance_id" {
  value = aws_instance.rails-form-training_for_operation.id
}

resource "aws_s3_bucket" "operation" {
  bucket = "operation-rails-form-training"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_cloudwatch_log_group" "operation" {
  name              = "/operation"
  retention_in_days = 180
}

resource "aws_ssm_document" "session_manager_run_shell" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<EOF
  {
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "${aws_s3_bucket.operation.id}",
      "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation.name}"
    }
  }
EOF
}