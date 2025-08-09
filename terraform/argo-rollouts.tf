# =============================================================================
# ARGO ROLLOUTS INSTALLATION AND CONFIGURATION
# =============================================================================

# Wait for cluster and add-ons to be ready
resource "time_sleep" "wait_for_cluster_for_rollouts" {
  create_duration = "30s"
  depends_on = [
    module.book_app_eks,
    module.eks_addons
  ]
}

# =============================================================================
# ARGO ROLLOUTS HELM INSTALLATION
# =============================================================================

resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  namespace        = var.argo_rollouts_namespace
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = var.argo_rollouts_chart_version

  values = [
    yamlencode({
      controller = {
        replicas = 1
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      dashboard = {
        enabled = true
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]

  depends_on = [time_sleep.wait_for_cluster_for_rollouts]
}

# =============================================================================
# WAIT FOR ARGO ROLLOUTS TO BE READY
# =============================================================================

resource "time_sleep" "wait_for_argo_rollouts" {
  create_duration = "30s"
  depends_on      = [helm_release.argo_rollouts]
}
