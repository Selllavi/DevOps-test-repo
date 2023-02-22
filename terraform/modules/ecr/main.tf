#
# Setup ECR for docker images and packaged helm charts
#
resource "aws_ecr_repository" "ecr_repository" {
  for_each             = toset(var.ecr_repositories)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}