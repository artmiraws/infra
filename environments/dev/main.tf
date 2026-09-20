data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "opentofu"
  }

  budget_thresholds = [50, 80, 100]

  github_app_secret_arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.github_app_secret_name}-??????"
}

module "vpc" {
  source = "../../modules/vpc"

  name         = "${var.project}-${var.environment}"
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
  cluster_name = var.cluster_name
  tags         = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = var.cluster_name
  subnet_ids   = module.vpc.private_subnet_ids

  kubernetes_version          = var.kubernetes_version
  node_instance_types         = var.node_instance_types
  node_desired_size           = var.node_desired_size
  node_min_size               = var.node_min_size
  node_max_size               = var.node_max_size
  cluster_public_access_cidrs = var.cluster_public_access_cidrs
  cluster_enabled_log_types   = var.cluster_enabled_log_types
  admin_principal_arns        = var.admin_principal_arns

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name       = "${var.project}-${var.environment}"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = [module.vpc.vpc_cidr]

  engine_version                  = var.db_engine_version
  database_name                   = var.db_name
  master_username                 = var.db_master_username
  min_capacity                    = var.db_min_capacity
  max_capacity                    = var.db_max_capacity
  backup_retention_period         = var.db_backup_retention_period
  skip_final_snapshot             = var.db_skip_final_snapshot
  deletion_protection             = var.db_deletion_protection
  enabled_cloudwatch_logs_exports = var.db_cloudwatch_logs_exports

  tags = local.common_tags
}

module "app_secrets" {
  source = "../../modules/app-secrets"

  name = "${var.project}-${var.environment}/app"

  tags = local.common_tags
}

module "eso" {
  source = "../../modules/eso"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
  secret_arns = [
    module.rds.master_user_secret_arn,
    module.app_secrets.secret_arn,
    local.github_app_secret_arn,
  ]

  tags = local.common_tags

  depends_on = [module.eks, module.rds]
}

module "ecr" {
  source = "../../modules/ecr"

  name                 = var.project
  image_tag_mutability = "MUTABLE"

  tags = local.common_tags
}

module "arc" {
  source = "../../modules/arc"

  cluster_name       = module.eks.cluster_name
  cluster_arn        = module.eks.cluster_arn
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_issuer        = module.eks.oidc_issuer
  ecr_repository_arn = module.ecr.repository_arn

  github_config_url      = var.github_config_url
  github_app_secret_name = var.github_app_secret_name

  ssm_parameter_path = "/${var.project}/${var.environment}"

  tags = local.common_tags

  depends_on = [module.eks, module.eso]
}

module "metrics_server" {
  source = "../../modules/metrics-server"

  depends_on = [module.eks]
}

module "cluster_autoscaler" {
  source = "../../modules/cluster-autoscaler"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
  region            = var.aws_region

  tags = local.common_tags

  depends_on = [module.eks]
}

module "infra_runner" {
  source = "../../modules/infra-runner"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer

  github_config_url = var.github_config_url

  tags = local.common_tags

  depends_on = [module.arc]
}

resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-${var.environment}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = toset([for threshold in local.budget_thresholds : tostring(threshold)])

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = tonumber(notification.value)
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.budget_alert_emails
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
