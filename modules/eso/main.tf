data "aws_region" "current" {}

locals {
  oidc_provider_host = replace(var.oidc_issuer, "https://", "")
}

data "aws_iam_policy_document" "assume" {
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

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "secrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = var.secret_arns
  }
}

resource "aws_iam_policy" "secrets" {
  name   = "${var.cluster_name}-external-secrets"
  policy = data.aws_iam_policy_document.secrets.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.secrets.arn
}

resource "helm_release" "this" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = {
        name = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }
      }

      extraObjects = [
        {
          apiVersion = "external-secrets.io/v1"
          kind       = "ClusterSecretStore"
          metadata = {
            name = var.secret_store_name
          }
          spec = {
            provider = {
              aws = {
                service = "SecretsManager"
                region  = data.aws_region.current.region
                auth = {
                  jwt = {
                    serviceAccountRef = {
                      name      = var.service_account_name
                      namespace = var.namespace
                    }
                  }
                }
              }
            }
          }
        }
      ]
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.secrets]
}
