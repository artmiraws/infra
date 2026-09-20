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
      values   = ["system:serviceaccount:${var.runner_namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-infra-runner"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = var.tags
}

# Dev compromise: the infra pipeline manages the whole stack, so this dedicated role (separate
# from the app runner) has broad permissions. Production would scope it.
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_eks_access_entry" "this" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.this.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.this.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.this]
}

resource "kubectl_manifest" "service_account" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = var.service_account_name
      namespace = var.runner_namespace
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
      }
    }
  })

  depends_on = [aws_iam_role.this]
}

resource "helm_release" "this" {
  name      = var.runner_scale_set_name
  chart     = "${path.module}/../arc/charts/gha-runner-scale-set-${var.chart_version}.tgz"
  namespace = var.runner_namespace
  wait      = true
  atomic    = true

  values = [
    yamlencode({
      githubConfigUrl    = var.github_config_url
      githubConfigSecret = var.github_secret_secret_name
      runnerScaleSetName = var.runner_scale_set_name
      minRunners         = 0
      maxRunners         = 1
      containerMode      = { type = "dind" }
      template = {
        spec = {
          serviceAccountName = var.service_account_name
        }
      }
    })
  ]

  depends_on = [kubectl_manifest.service_account]
}
