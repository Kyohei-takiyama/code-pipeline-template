data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "codepipeline:PutJobSuccessResult",
      "codepipeline:PutJobFailureResult",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "iam:PassRole",
    ]
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.prefix}-artifacts"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 7
    }
  }
}

resource "aws_codepipeline" "this" {
  name     = var.prefix
  role_arn = module.codepipeline_role.iam_role_arn

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["Source"]

      # Github configuration reference: https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#structure-configuration-examples
      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = "main"
        PollForSourceChanges = "false"
        OAuthToken           = var.github_token
      }
    }
  }

  # https://docs.aws.amazon.com/codepipeline/latest/userguide/update-github-action-connections.html
  # 本当はVersion2が推奨
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.this.name
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
      version         = "1"
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = aws_ecs_cluster.this.name
        ServiceName = aws_ecs_service.this.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }
}

resource "aws_codepipeline_webhook" "this" {
  name            = "${var.prefix}-webhook"
  target_pipeline = aws_codepipeline.this.name
  target_action   = aws_codepipeline.this.stage[0].action[0].name
  authentication  = "GITHUB_HMAC"

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }

  authentication_configuration {
    secret_token = var.github_token
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

# Wire the CodePipeline webhook into a GitHub repository.
resource "github_repository_webhook" "this" {
  repository = var.github_repo
  events     = ["push"]
  configuration {
    url          = aws_codepipeline_webhook.this.url
    content_type = "json"
    secret       = var.github_token
    insecure_ssl = false
  }
}

provider "github" {
  organization = var.github_owner
  token        = var.github_token
}
