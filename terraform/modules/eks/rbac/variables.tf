variable "kubernetes_resources_name_prefix" {
  type        = string
  default     = ""
  description = "Prefix for kubernetes resources name. For example `tf-module-`"
}

variable "kubernetes_namespace" {
  type        = string
  default     = "kube-system"
  description = "Namespace for admin ServiceAccount"
}