map_roles = [
  {
    "groups" : ["system:masters"],
    "rolearn" : "arn:aws:iam::723915311050:role/build-role-dev",
    "username" : "eks-admin"
  }
]

map_users = [
  {
    "groups" : ["system:masters"],
    "userarn" : "arn:aws:iam::723915311050:user/some-user",
    "username" : "additional-user"
  }
]

repo_name             = "DevOps-test-repo"
branch                = "main"
repo_owner            = "Selllavi"
github_oauth_token    = "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"
aws_account_id        = "723915311050"
app_bucket_name       = "s3-website-sdjfhwerh"
github_webhooks_token = "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"
region                = "eu-west-1"
image_repo_name       = "docker-weather"
image_tag             = "1.0"
helm_repo_name        = "chart-weather"
helm_tag              = "1.0.0"
privileged_mode       = true
chart_release_name    = "chart-weather"
force_destroy         = true
ecr_repositories      = ["docker-weather", "chart-weather"]
helm_namespace        = "weather-namespace"
helm_namespace_create = true
domain                = "domain.org"