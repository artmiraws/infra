resource "random_password" "session_key" {
  length  = 64
  special = false
}

resource "random_password" "admin_password" {
  length           = 24
  special          = true
  override_special = "!#%^&*()-_=+"
}

resource "random_password" "cleanup_token" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "this" {
  name = var.name

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode({
    SESSION_KEY    = random_password.session_key.result
    ADMIN_USER     = var.admin_user
    ADMIN_PASSWORD = random_password.admin_password.result
    CLEANUP_TOKEN  = random_password.cleanup_token.result
  })
}
