# The platform handbook (platform-docs) is deployed as an application on the platform: its own image
# repository, hostname certificate, and Argo CD Application, wired through the same pattern as the
# TodoList app. See ADR-013 and the PLATFORM-DOCS task.
module "ecr_docs" {
  source = "../../modules/ecr"

  name                 = "platform-docs"
  image_tag_mutability = "MUTABLE"

  tags = local.common_tags
}

module "acm_docs" {
  source = "../../modules/acm"

  hostname = "${var.platform_docs_subdomain}.${var.base_domain}"
  zone_id  = data.aws_route53_zone.this.zone_id

  tags = local.common_tags
}

locals {
  docs_values = {
    image = {
      repository = module.ecr_docs.repository_url
    }

    ingress = {
      host = module.acm_docs.hostname
      annotations = {
        "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
        "alb.ingress.kubernetes.io/certificate-arn" = module.acm_docs.certificate_arn
      }
    }
  }

  docs_ssm_parameters = {
    app_hostname            = module.acm_docs.hostname
    ingress_certificate_arn = module.acm_docs.certificate_arn
    ecr_repository_url      = module.ecr_docs.repository_url
  }
}

# Gated: the platform-docs repository must exist and contain charts/platform-docs before Argo CD can
# reconcile this Application. Enable with platform_docs_enabled = true.
module "argocd_app_docs" {
  source = "../../modules/argocd-app"
  count  = var.platform_docs_enabled ? 1 : 0

  name            = "platform-docs"
  namespace       = var.platform_docs_namespace
  repo_url        = var.platform_docs_repo_url
  target_revision = "main"
  chart_path      = "charts/platform-docs"
  release_name    = "platform-docs"
  value_files     = ["gitops/dev.yaml"]
  values_object   = local.docs_values

  depends_on = [module.argocd, module.alb, module.acm_docs]
}

resource "aws_ssm_parameter" "docs" {
  for_each = local.docs_ssm_parameters

  name  = "/${var.project}/${var.environment}/platform-docs/${each.key}"
  type  = "String"
  value = each.value
  tags  = local.common_tags
}
