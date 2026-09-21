data "aws_route53_zone" "this" {
  name         = var.base_domain
  private_zone = false
}

module "alb" {
  source = "../../modules/alb"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
  vpc_id            = module.vpc.vpc_id
  region            = var.aws_region

  tags = local.common_tags

  depends_on = [module.eks]
}

module "dns" {
  source = "../../modules/dns"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
  zone_id           = data.aws_route53_zone.this.zone_id
  base_domain       = var.base_domain
  region            = var.aws_region

  tags = local.common_tags

  depends_on = [module.eks]
}
