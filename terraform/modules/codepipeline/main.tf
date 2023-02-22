#
# Setup Code Pipeline with CodeBuild to create CI/CD for application
#

data "template_file" "buildspec" {
  template = file("modules/codepipeline/buildspec.yml")
  vars     = {
    env = var.env
  }
}

resource "kubernetes_namespace" "kubernetes_dashboard" {
  count = var.helm_namespace_create ? 1 : 0

  metadata {
    name = var.helm_namespace
  }
}

resource "aws_codebuild_project" "static_web_build" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "static-web-build"
  queued_timeout = 480
  service_role   = aws_iam_role.static_build_role.arn
  tags           = {
    Environment = var.env
  }

  artifacts {
    encryption_disabled    = false
    name                   = "static-web-build-${var.env}"
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.build_compute_type
    image                       = var.build_image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.privileged_mode
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    buildspec           = data.template_file.buildspec.rendered
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
}

resource "aws_codepipeline" "static_web_pipeline" {
  depends_on = [
    aws_s3_bucket.artifacts_bucket
  ]
  name     = "static-web-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn
  tags     = {
    Environment = var.env
  }

  artifact_store {
    location = var.app_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category      = "Source"
      configuration = {
        OAuthToken           = var.github_oauth_token
        PollForSourceChanges = var.poll_source_changes
        Branch               = var.branch
        Owner                = var.repo_owner
        PollForSourceChanges = "false"
        Repo                 = var.repo_name
      }
      input_artifacts  = []
      name             = "Source"
      output_artifacts = [
        "SourceArtifact",
      ]
      owner     = "ThirdParty"
      provider  = "GitHub"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Build"

    action {
      category      = "Build"
      configuration = {
        "EnvironmentVariables" = jsonencode(
          [
            {
              name  = "environment"
              type  = "PLAINTEXT"
              value = var.env
            },
            {
              name  = "IMAGE_REPO_NAME"
              type  = "PLAINTEXT"
              value = var.image_repo_name
            },
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = var.image_tag
            },
            {
              name  = "CHART_REPO_NAME"
              type  = "PLAINTEXT"
              value = var.helm_repo_name
            },
            {
              name  = "CHART_TAG"
              type  = "PLAINTEXT"
              value = var.helm_tag
            },
            {
              name  = "HELM_NAMESPACE"
              type  = "PLAINTEXT"
              value = var.helm_namespace
            },
            {
              name  = "AWS_ACCOUNT_ID"
              type  = "PLAINTEXT"
              value = var.aws_account_id
            },
            {
              name  = "EKS_CLUSTER"
              type  = "PLAINTEXT"
              value = var.eks_cluster
            },
            {
              name  = "CHART_RELEASE_NAME"
              type  = "PLAINTEXT"
              value = var.chart_release_name
            },
          ]
        ),
        "ProjectName" = "static-web-build",
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      name             = "Build"
      output_artifacts = [
        "BuildArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeBuild"
      run_order = 1
      version   = "1"
    }
  }
}

resource "aws_codepipeline_webhook" "codepipeline_webhook" {
  name            = "webhook"
  authentication  = var.webhook_authentication
  target_action   = "Source"
  target_pipeline = "static-web-pipeline"

  authentication_configuration {
    secret_token = random_string.github_secret.result#var.github_webhooks_token
  }

  filter {
    json_path    = var.webhook_filter_json_path
    match_equals = var.webhook_filter_match_equals
  }
}

module "github_webhook" {
  source  = "cloudposse/repository-webhooks/github"
  version = "0.12.0"

  github_organization  = var.repo_owner
  github_repositories  = [var.repo_name]
  github_token         = var.github_webhooks_token
  webhook_url          = aws_codepipeline_webhook.codepipeline_webhook.url
  webhook_secret       = random_string.github_secret.result
  webhook_content_type = "json"
  events               = var.github_webhook_events
}

resource "random_string" "github_secret" {
  length  = 99
  special = false
}

resource "aws_s3_bucket" "artifacts_bucket" {
  bucket        = var.app_bucket_name
  force_destroy = var.force_destroy
}