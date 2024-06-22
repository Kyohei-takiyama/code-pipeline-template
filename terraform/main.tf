module "http_sg" {
  source      = "./security_group"
  name        = "${var.prefix}-http-security-group"
  vpc_id      = aws_vpc.this.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "${var.prefix}-https-security-group"
  vpc_id      = aws_vpc.this.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "${var.prefix}-http-redirect-security-group"
  vpc_id      = aws_vpc.this.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "${var.prefix}-nginx-security-group"
  vpc_id      = aws_vpc.this.id
  port        = 80
  cidr_blocks = [aws_vpc.this.cidr_block]
}

module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "${var.prefix}-ecs-task-execution-role"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
  identifier = "ecs-tasks.amazonaws.com"
}

module "codebuild_role" {
  source     = "./iam_role"
  name       = "${var.prefix}-codebuild-role"
  policy     = data.aws_iam_policy_document.codebuild.json
  identifier = "codebuild.amazonaws.com"
}

module "codepipeline_role" {
  source     = "./iam_role"
  name       = "${var.prefix}-codepipeline-role"
  policy     = data.aws_iam_policy_document.codepipeline.json
  identifier = "codepipeline.amazonaws.com"
}
