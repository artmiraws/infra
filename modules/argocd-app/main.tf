locals {
  sync_policy = merge(
    { syncOptions = ["CreateNamespace=true"] },
    var.automated_sync ? { automated = { prune = true, selfHeal = true } } : {},
  )
}

# The Application CRD is installed by the Argo CD Helm release, so this is applied afterwards (Helm
# cannot map a custom resource installed in the same release as its CRD). The environment root
# depends_on the Argo CD module.
resource "kubectl_manifest" "this" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.name
      namespace = var.argocd_namespace
    }
    spec = {
      project = var.project

      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = var.chart_path
        helm = {
          valueFiles   = var.value_files
          valuesObject = var.values_object
        }
      }

      destination = {
        server    = var.destination_server
        namespace = var.namespace
      }

      syncPolicy = local.sync_policy
    }
  })
}
