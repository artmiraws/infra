# The platform contract (ADR-013): environment facts are environment-scoped and application facts are
# namespaced under apps/<app>. Applications read these; they never read Terraform state.
locals {
  platform_parameters = {
    cluster_name           = module.eks.cluster_name
    region                 = var.aws_region
    ecr_registry           = split("/", data.aws_ecr_repository.this.repository_url)[0]
    ingress_class          = "alb"
    external_secrets_store = module.eso.secret_store_name
  }

  app_parameters = {
    image_repository = data.aws_ecr_repository.this.repository_url
    runner_scale_set = module.arc.runner_scale_set_name
    hostname         = module.app_todolist.hostname
    certificate_arn  = module.app_todolist.certificate_arn
    db_host          = module.app_todolist.db_cluster_endpoint
    db_port          = tostring(module.app_todolist.db_cluster_port)
    db_name          = module.app_todolist.db_name
    db_secret_arn    = module.app_todolist.db_master_user_secret_arn
    app_secret_arn   = module.app_todolist.app_secret_arn
  }
}

resource "aws_ssm_parameter" "platform" {
  for_each = local.platform_parameters

  name  = "/platform/${var.environment}/${each.key}"
  type  = "String"
  value = each.value
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "app" {
  for_each = local.app_parameters

  name  = "/platform/${var.environment}/apps/${var.project}/${each.key}"
  type  = "String"
  value = each.value
  tags  = local.common_tags
}
