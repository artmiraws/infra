# Everything that belongs to the TodoList application (not the platform): its database, its
# application secret, its hostname certificate, and its Argo CD Application. The platform supplies
# the inputs (VPC, cluster, zone, registry, store); this module owns the app-specific resources and
# publishes the values the application needs. See ADR-013.

module "rds" {
  source = "../rds"

  name       = var.name
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  allowed_cidr_blocks = var.allowed_cidr_blocks

  engine_version                  = var.db_engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  min_capacity                    = var.db_min_capacity
  max_capacity                    = var.db_max_capacity
  backup_retention_period         = var.db_backup_retention_period
  skip_final_snapshot             = var.db_skip_final_snapshot
  deletion_protection             = var.db_deletion_protection
  enabled_cloudwatch_logs_exports = var.db_cloudwatch_logs_exports

  tags = var.tags
}

module "app_secrets" {
  source = "../app-secrets"

  name = var.app_secret_name

  tags = var.tags
}

module "acm" {
  source = "../acm"

  hostname = var.hostname
  zone_id  = var.zone_id

  tags = var.tags
}

locals {
  app_values = {
    image = {
      repository = var.ecr_repository_url
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
      host = module.acm.hostname
      annotations = {
        "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
        "alb.ingress.kubernetes.io/certificate-arn" = module.acm.certificate_arn
      }
    }
  }
}

# Argo CD owns the application release (ADR-012). The pipeline only updates the digest file in Git.
module "argocd_app" {
  source = "../argocd-app"

  # The Application and Helm release names match the resources Helm already created, so Argo CD
  # adopts them instead of creating a second set (the chart names objects from the release name).
  name            = var.app_name
  namespace       = var.namespace
  repo_url        = var.repo_url
  target_revision = var.target_revision
  chart_path      = var.chart_path
  release_name    = var.release_name
  value_files     = var.value_files
  values_object   = local.app_values
}
