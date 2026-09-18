resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-db" })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-db"
  description = "PostgreSQL access for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-db" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = toset(var.allowed_cidr_blocks)

  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.this.id
  description       = "PostgreSQL from ${each.value}"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound"
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = var.name
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.engine_version
  database_name      = var.database_name
  master_username    = var.master_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  storage_encrypted               = true
  backup_retention_period         = var.backup_retention_period
  copy_tags_to_snapshot           = true
  skip_final_snapshot             = var.skip_final_snapshot
  deletion_protection             = var.deletion_protection
  apply_immediately               = var.apply_immediately
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  instance_class     = "db.serverless"

  apply_immediately = var.apply_immediately

  tags = merge(var.tags, { Name = "${var.name}-writer" })
}
