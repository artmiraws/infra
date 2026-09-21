# Argo CD is reached with `kubectl port-forward` (see in-progress.md), not exposed publicly.
module "argocd" {
  source = "../../modules/argocd"

  depends_on = [module.eks]
}

# The TodoList application: its database, application secret, hostname certificate, and Argo CD
# Application. The platform supplies the VPC, cluster, zone, registry, and store. See ADR-013.
module "app_todolist" {
  source = "../../modules/app-todolist"

  name       = "${var.project}-${var.environment}"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = [module.vpc.vpc_cidr]

  db_engine_version          = var.db_engine_version
  database_name              = var.db_name
  master_username            = var.db_master_username
  db_min_capacity            = var.db_min_capacity
  db_max_capacity            = var.db_max_capacity
  db_backup_retention_period = var.db_backup_retention_period
  db_skip_final_snapshot     = var.db_skip_final_snapshot
  db_deletion_protection     = var.db_deletion_protection
  db_cloudwatch_logs_exports = var.db_cloudwatch_logs_exports

  app_secret_name = "${var.project}-${var.environment}/app"

  hostname = "${var.app_subdomain}.${var.base_domain}"
  zone_id  = data.aws_route53_zone.this.zone_id

  ecr_repository_url = data.aws_ecr_repository.this.repository_url

  app_name        = "todolist"
  namespace       = var.app_namespace
  repo_url        = var.app_repo_url
  target_revision = "main"
  chart_path      = "charts/todolist"
  release_name    = "todolist"
  value_files     = ["gitops/${var.environment}.yaml"]

  tags = local.common_tags

  # The Argo CD Application is created once Argo CD, the ALB, and DNS exist. The ClusterSecretStore
  # (module.eso) is created after this module, so Argo CD may briefly fail the ExternalSecret until
  # the store appears, then self-heals.
  depends_on = [module.argocd, module.alb, module.dns]
}
