variable "ecr_repositories" {
  type        = list(string)
  default     = []
  description = "Names of ECR to be created."
}
