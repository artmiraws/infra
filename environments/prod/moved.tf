# The application's resources moved out of the platform root into modules/app-todolist (ADR-013).
# These blocks let OpenTofu relocate the existing resources in state without recreating them.

moved {
  from = module.rds
  to   = module.app_todolist.module.rds
}

moved {
  from = module.app_secrets
  to   = module.app_todolist.module.app_secrets
}

moved {
  from = module.argocd_app
  to   = module.app_todolist.module.argocd_app
}

# The application hostname certificate moved from modules/dns into the app module's ACM module.
moved {
  from = module.dns.aws_acm_certificate.this
  to   = module.app_todolist.module.acm.aws_acm_certificate.this
}

moved {
  from = module.dns.aws_route53_record.validation
  to   = module.app_todolist.module.acm.aws_route53_record.validation
}

moved {
  from = module.dns.aws_acm_certificate_validation.this
  to   = module.app_todolist.module.acm.aws_acm_certificate_validation.this
}
