locals {
  oidc_provider_host = replace(var.oidc_issuer, "https://", "")
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "runner_assume" {
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
      values   = ["system:serviceaccount:${var.runner_namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${var.cluster_name}-arc-runner"
  assume_role_policy = data.aws_iam_policy_document.runner_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "runner" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [var.ecr_repository_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [var.cluster_arn]
  }

  dynamic "statement" {
    for_each = var.ssm_parameter_path == "" ? [] : [1]

    content {
      effect = "Allow"

      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath",
      ]

      resources = [
        "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_path}/*",
      ]
    }
  }
}

resource "aws_iam_role_policy" "runner" {
  name   = "${var.cluster_name}-arc-runner"
  role   = aws_iam_role.runner.id
  policy = data.aws_iam_policy_document.runner.json
}

# Dev compromise: the runner deploys the app with Helm, so it gets cluster admin.
resource "aws_eks_access_entry" "runner" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.runner.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "runner" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.runner.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.runner]
}

resource "kubectl_manifest" "controller_namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name   = var.controller_namespace
      labels = { "app.kubernetes.io/part-of" = "arc" }
    }
  })
}

resource "kubectl_manifest" "runner_namespace" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name   = var.runner_namespace
      labels = { "app.kubernetes.io/part-of" = "arc" }
    }
  })
}

resource "kubectl_manifest" "runner_service_account" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = var.service_account_name
      namespace = var.runner_namespace
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.runner.arn
      }
    }
  })

  depends_on = [kubectl_manifest.runner_namespace, aws_iam_role.runner]
}

resource "kubectl_manifest" "github_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.github_secret_secret_name
      namespace = var.runner_namespace
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = var.store_name
        kind = "ClusterSecretStore"
      }
      target = {
        name           = var.github_secret_secret_name
        creationPolicy = "Owner"
      }
      data = [
        { secretKey = "github_app_id", remoteRef = { key = var.github_app_secret_name, property = "github_app_id" } },
        { secretKey = "github_app_installation_id", remoteRef = { key = var.github_app_secret_name, property = "github_app_installation_id" } },
        { secretKey = "github_app_private_key", remoteRef = { key = var.github_app_secret_name, property = "github_app_private_key" } },
      ]
    }
  })

  depends_on = [kubectl_manifest.runner_namespace]
}

resource "helm_release" "controller" {
  name      = "arc"
  chart     = "${path.module}/charts/gha-runner-scale-set-controller-${var.chart_version}.tgz"
  namespace = var.controller_namespace
  wait      = true
  atomic    = true

  depends_on = [kubectl_manifest.controller_namespace]
}

resource "helm_release" "scale_set" {
  name      = "arc-runner-set"
  chart     = "${path.module}/charts/gha-runner-scale-set-${var.chart_version}.tgz"
  namespace = var.runner_namespace
  wait      = true
  atomic    = true

  values = [
    yamlencode({
      githubConfigUrl    = var.github_config_url
      githubConfigSecret = var.github_secret_secret_name
      runnerScaleSetName = var.runner_scale_set_name
      minRunners         = var.min_runners
      maxRunners         = var.max_runners
      containerMode      = { type = "dind" }
      template = {
        spec = {
          serviceAccountName = var.service_account_name
        }
      }
    })
  ]

  depends_on = [
    helm_release.controller,
    kubectl_manifest.runner_service_account,
    kubectl_manifest.github_secret,
  ]
}
