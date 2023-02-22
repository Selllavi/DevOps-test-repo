resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://charts.helm.sh/stable"
  namespace  = "kube-system"
  chart      = "metrics-server"
  version    = "2.11.1"
}