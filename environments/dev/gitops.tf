module "argocd" {
  source = "../../modules/argocd"

  depends_on = [module.eks]
}

# Non-secret wiring injected into the application chart. Keeping it here (instead of a committed
# values file) avoids account IDs, ARNs, and hostnames in Git; the only committed value is the image
# digest. See ADR-012.
locals {
  app_values = {
    image = {
      repository = module.ecr.repository_url
    }

    config = {
      dbHost = module.rds.cluster_endpoint
      dbName = module.rds.database_name
    }

    externalSecret = {
      dbSecretArn  = module.rds.master_user_secret_arn
      appSecretArn = module.app_secrets.secret_arn
    }

    ingress = {
      host = module.dns.hostname
      annotations = {
        "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
        "alb.ingress.kubernetes.io/certificate-arn" = module.dns.certificate_arn
      }
    }
  }
}

# Argo CD owns the application release (ADR-012). The pipeline only updates the digest file in Git.
module "argocd_app" {
  source = "../../modules/argocd-app"

  name            = "todolist-${var.environment}"
  namespace       = var.app_namespace
  repo_url        = var.app_repo_url
  target_revision = "main"
  chart_path      = "charts/todolist"
  value_files     = ["gitops/${var.environment}.yaml"]
  values_object   = local.app_values

  depends_on = [module.argocd, module.alb, module.dns, module.eso]
}
