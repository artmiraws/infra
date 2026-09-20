locals {
  # TLS terminates at the ALB, so Argo CD's server runs in insecure (HTTP) mode when published.
  server = merge(
    { replicas = 1, insecure = var.server_insecure },
    var.ingress_enabled ? {
      ingress = {
        enabled          = true
        ingressClassName = var.ingress_class_name
        hostname         = var.ingress_host
        annotations      = var.ingress_annotations
      }
    } : {},
  )
}

resource "helm_release" "this" {
  name             = "argocd"
  chart            = "${path.module}/charts/argo-cd-${var.chart_version}.tgz"
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  atomic           = true
  timeout          = 900

  values = [
    yamlencode({
      # Keep the control-plane footprint small on the t3.small nodes. Dex and notifications are not
      # used (SSO and alerting are out of scope for the demo); the ApplicationSet controller stays.
      dex           = { enabled = false }
      notifications = { enabled = false }

      server     = local.server
      controller = { replicas = 1 }
      repoServer = { replicas = 1 }
      redis      = { enabled = true }
    })
  ]
}
