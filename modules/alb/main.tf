locals {
  oidc_provider_host = replace(var.oidc_issuer, "https://", "")
  policy_json        = file("${path.module}/iam_policy.json")
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
  name               = "${var.cluster_name}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

resource "aws_iam_policy" "this" {
  name   = "${var.cluster_name}-aws-load-balancer-controller"
  policy = local.policy_json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name      = "aws-load-balancer-controller"
  chart     = "${path.module}/charts/aws-load-balancer-controller-${var.chart_version}.tgz"
  namespace = var.namespace
  wait      = true
  atomic    = true

  values = [
    yamlencode({
      clusterName  = var.cluster_name
      region       = var.region
      vpcId        = var.vpc_id
      replicaCount = 1

      # Reuse the webhook TLS secret across upgrades. Without this the chart regenerates
      # the self-signed cert on every Helm run, briefly breaking the (Fail-policy) webhooks
      # and blocking Service creation.
      keepTLSSecret = true

      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }
      }
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.this]
}
