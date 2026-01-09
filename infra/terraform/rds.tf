# rds.tf

################################################################################
# RDS PostgreSQL
################################################################################

# Security Group para o RDS
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name        = "${local.name}-rds-sg"
    Environment = var.environment
  })
}

# Subnet Group para o RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${local.name}-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(local.tags, {
    Name        = "${local.name}-rds-subnet-group"
    Environment = var.environment
  })
}

# Parameter Group (opcional - para tuning)
resource "aws_db_parameter_group" "postgres" {
  name        = "${local.name}-postgres-params"
  family      = "postgres17"
  description = "Custom parameter group for ${local.name}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(local.tags, {
    Environment = var.environment
  })
}

# Gera senha aleatória para o RDS
resource "random_password" "rds_password" {
  length  = 32
  special = true
  # Remove caracteres que podem dar problema em connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# RDS Instance
resource "aws_db_instance" "postgres" {
  identifier = "${local.name}-postgres"

  # Engine
  engine               = "postgres"
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  allocated_storage    = var.rds_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true
  
  # IOPS (só se usar io1 ou gp3)
  iops = var.rds_instance_class == "db.t3.micro" ? null : 3000

  # Database
  db_name  = var.rds_database_name
  username = var.rds_username
  password = random_password.rds_password.result
  port     = 5432

  # Network
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.rds_multi_az

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Backup
  backup_retention_period   = var.rds_backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = var.rds_skip_final_snapshot ? null : "${local.name}-postgres-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot     = true

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled    = var.rds_instance_class != "db.t3.micro" # t3.micro não suporta
  performance_insights_retention_period = var.rds_instance_class != "db.t3.micro" ? 7 : null

  # Maintenance
  auto_minor_version_upgrade = true
  deletion_protection        = var.environment == "prod" ? true : false

  tags = merge(local.tags, {
    Name        = "${local.name}-postgres"
    Environment = var.environment
  })
}

# IAM Role para Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Armazena a senha no Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${local.name}-rds-credentials"
  description             = "RDS PostgreSQL credentials for ${local.name}"
  recovery_window_in_days = 0

  tags = merge(local.tags, {
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username            = aws_db_instance.postgres.username
    password            = random_password.rds_password.result
    engine              = "postgres"
    host                = aws_db_instance.postgres.address
    port                = aws_db_instance.postgres.port
    dbname              = aws_db_instance.postgres.db_name
    dbInstanceIdentifier = aws_db_instance.postgres.identifier
  })
}

# IAM Policy para ler o secret (pros pods)
resource "aws_iam_policy" "rds_secret_read" {
  name        = "${local.name}-rds-secret-read"
  description = "Policy para ler secrets do RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      }
    ]
  })

  tags = merge(local.tags, {
    Environment = var.environment
  })
}