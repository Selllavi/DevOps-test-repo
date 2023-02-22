variable "worker_iam_role_name" {
  type        = string
  default     = ""
  description = "Kubernetes worker iam role name."
}
variable "cluster_id" {
  type        = string
  default     = ""
  description = "Kubernetes cluster id."
}

variable "helm_release" {
  type    = map(string)
  default = {}
}

variable "eks_extra_config" {
  type    = any
  default = {}
}