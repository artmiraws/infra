locals {
  oidc_provider_host = replace(var.oidc_issuer, "https://", "")
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.hostname
  validation_method = "DNS"

  tags = merge(var.tags, { Name = var.hostname })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for option in aws_acm_certificate.this.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/${var.zone_id}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name   = "${var.cluster_name}-external-dns"
  policy = data.aws_iam_policy_document.external_dns.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  chart            = "${path.module}/charts/external-dns-${var.chart_version}.tgz"
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  atomic           = true

  values = [
    yamlencode({
      provider      = "aws"
      policy        = "upsert-only"
      sources       = ["ingress"]
      domainFilters = [var.base_domain]
      txtOwnerId    = var.cluster_name

      env = [
        { name = "AWS_REGION", value = var.region },
      ]

      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
        }
      }
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.external_dns]
}
