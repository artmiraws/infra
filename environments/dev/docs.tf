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

# GitHub self-hosted runners are repository-scoped, so the platform-docs repository needs its own
# scale set (the app runner registers to the app repository). Shares the ARC controller and the
# GitHub App secret created by modules/arc.
module "arc_docs" {
  source = "../../modules/arc-runner"

  name                  = "docs"
  cluster_name          = module.eks.cluster_name
  cluster_arn           = module.eks.cluster_arn
  oidc_provider_arn     = module.eks.oidc_provider_arn
  oidc_issuer           = module.eks.oidc_issuer
  ecr_repository_arn    = module.ecr_docs.repository_arn
  github_config_url     = var.platform_docs_repo_url
  runner_scale_set_name = "arc-docs-runner"
  release_name          = "arc-docs-runner"
  service_account_name  = "arc-docs-runner"
  ssm_parameter_path    = "/${var.project}/${var.environment}"

  tags = local.common_tags

  depends_on = [module.arc, module.eso]
}

# The docs pipeline applies the static-site infrastructure (S3 + CloudFront + ACM + Route53) and syncs
# the built site, so its runner needs those services. See the platform-docs repository.
data "aws_iam_policy_document" "docs_deploy" {
  statement {
    sid       = "SiteBucket"
    actions   = ["s3:ListBucket*", "s3:GetBucket*", "s3:PutBucket*", "s3:DeleteBucket*"]
    resources = ["arn:aws:s3:::platform-docs-*"]
  }

  statement {
    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:DeleteObject*",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["arn:aws:s3:::platform-docs-*/*"]
  }

  statement {
    sid       = "StateBucket"
    actions   = ["s3:ListBucket*", "s3:GetBucket*"]
    resources = ["arn:aws:s3:::${var.project}-tfstate-${data.aws_caller_identity.current.account_id}"]
  }

  # CloudFront creates a service-linked role on first use.
  statement {
    sid       = "ServiceLinkedRole"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::*:role/aws-service-role/cloudfront.amazonaws.com/*"]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["cloudfront.amazonaws.com"]
    }
  }

  statement {
    actions = ["s3:GetObject*", "s3:PutObject*", "s3:DeleteObject*"]
    resources = [
      "arn:aws:s3:::${var.project}-tfstate-${data.aws_caller_identity.current.account_id}/platform-docs/*",
    ]
  }

  statement {
    sid = "CloudFront"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListDistributions",
      "cloudfront:TagResource",
      "cloudfront:ListTagsForResource",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:ListOriginAccessControls",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Acm"
    actions = [
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:AddTagsToCertificate",
      "acm:ListTagsForCertificate",
      "acm:DeleteCertificate",
      "acm:ListCertificates",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Route53Records"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone",
      "route53:ListTagsForResource",
      "route53:ListTagsForResources",
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.this.zone_id}"]
  }

  statement {
    sid       = "Route53List"
    actions   = ["route53:ListHostedZones", "route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "docs_deploy" {
  name   = "${var.cluster_name}-arc-runner-docs-deploy"
  policy = data.aws_iam_policy_document.docs_deploy.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "docs_deploy" {
  role       = module.arc_docs.runner_role_name
  policy_arn = aws_iam_policy.docs_deploy.arn
}
