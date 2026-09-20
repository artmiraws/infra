resource "helm_release" "this" {
  name      = "metrics-server"
  chart     = "${path.module}/charts/metrics-server-${var.chart_version}.tgz"
  namespace = var.namespace
  wait      = true
  atomic    = true
}
