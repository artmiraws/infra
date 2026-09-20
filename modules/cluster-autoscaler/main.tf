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
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "autoscaler" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name   = "${var.cluster_name}-cluster-autoscaler"
  policy = data.aws_iam_policy_document.autoscaler.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name      = "cluster-autoscaler"
  chart     = "${path.module}/charts/cluster-autoscaler-${var.chart_version}.tgz"
  namespace = var.namespace
  wait      = true
  atomic    = true

  values = [
    yamlencode({
      autoDiscovery = { clusterName = var.cluster_name }
      awsRegion     = var.region
      replicaCount  = var.replica_count
      image         = { tag = var.image_tag }

      rbac = {
        serviceAccount = {
          name = var.service_account_name
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
          }
        }
      }

      extraArgs = {
        "balance-similar-node-groups" = "true"
        "skip-nodes-with-system-pods" = "false"
      }
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.this]
}
