#
# Setup Admin User account RBAC and Kubernetes namespace
#
resource "kubernetes_namespace" "kubernetes-dashboard" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}kubernetes-dashboard"
  }
}

resource "kubernetes_service_account" "admin-user" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}admin-user"
    namespace = var.kubernetes_namespace
  }
}

resource "kubernetes_cluster_role_binding" "admin-user-binding" {
  depends_on = [kubernetes_service_account.admin-user]
  metadata {
    name = "${var.kubernetes_resources_name_prefix}admin-user-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"  # predefined cluster role
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.admin-user.metadata.0.name
    namespace = kubernetes_service_account.admin-user.metadata.0.namespace
  }
}