locals {
  ssm_parameters = {
    cluster_name                = module.eks.cluster_name
    ecr_repository_url          = module.ecr.repository_url
    db_host                     = module.app_todolist.db_cluster_endpoint
    db_port                     = tostring(module.app_todolist.db_cluster_port)
    db_name                     = module.app_todolist.db_name
    db_secret_arn               = module.app_todolist.db_master_user_secret_arn
    app_secret_arn              = module.app_todolist.app_secret_arn
    app_hostname                = module.app_todolist.hostname
    ingress_certificate_arn     = module.app_todolist.certificate_arn
    external_secrets_store_name = module.eso.secret_store_name
    runner_scale_set_name       = module.arc.runner_scale_set_name
  }
}

# Publish the non-secret wiring the app pipeline needs, so CI reads it from SSM instead of
# committing it. Secrets stay in Secrets Manager.
resource "aws_ssm_parameter" "this" {
  for_each = local.ssm_parameters

  name  = "/${var.project}/${var.environment}/${each.key}"
  type  = "String"
  value = each.value
  tags  = local.common_tags
}
