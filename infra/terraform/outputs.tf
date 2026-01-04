# outputs.tf

################################################################################
# EKS Outputs
################################################################################

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "cluster_region" {
  description = "Região do cluster"
  value       = local.region
}

################################################################################
# SQS Outputs
################################################################################

output "sqs_queue_urls" {
  description = "URLs das filas SQS"
  value = {
    order_to_kitchen = aws_sqs_queue.order_to_kitchen.url
    kitchen_to_order = aws_sqs_queue.kitchen_to_order.url
    payment_to_order = aws_sqs_queue.payment_to_order.url
    order_to_payment = aws_sqs_queue.order_to_payment.url
  }
}

output "sqs_queue_names" {
  description = "Nomes das filas SQS"
  value = {
    order_to_kitchen = aws_sqs_queue.order_to_kitchen.name
    kitchen_to_order = aws_sqs_queue.kitchen_to_order.name
    payment_to_order = aws_sqs_queue.payment_to_order.name
    order_to_payment = aws_sqs_queue.order_to_payment.name
  }
}

output "sqs_queue_arns" {
  description = "ARNs das filas SQS"
  value = {
    order_to_kitchen = aws_sqs_queue.order_to_kitchen.arn
    kitchen_to_order = aws_sqs_queue.kitchen_to_order.arn
    payment_to_order = aws_sqs_queue.payment_to_order.arn
    order_to_payment = aws_sqs_queue.order_to_payment.arn
  }
}

################################################################################
# RDS Outputs
################################################################################

output "rds_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS hostname"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "RDS username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "rds_secret_arn" {
  description = "ARN do secret com as credenciais do RDS"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "rds_secret_name" {
  description = "Nome do secret no Secrets Manager"
  value       = aws_secretsmanager_secret.rds_credentials.name
}

################################################################################
# Config Map Template (para facilitar deploy do K8s)
################################################################################

output "k8s_configmap_data" {
  description = "Dados para o ConfigMap do K8s (copy/paste ready)"
  value = {
    DATABASE_HOST                = aws_db_instance.postgres.address
    DATABASE_PORT                = tostring(aws_db_instance.postgres.port)
    DATABASE_NAME                = aws_db_instance.postgres.db_name
    DATABASE_USER                = aws_db_instance.postgres.username
    AWS_REGION                   = local.region
    ORDER_TO_KITCHEN_QUEUE_URL   = aws_sqs_queue.order_to_kitchen.url
    ORDER_TO_KITCHEN_NAME        = aws_sqs_queue.order_to_kitchen.name
    KITCHEN_TO_ORDER_QUEUE_URL   = aws_sqs_queue.kitchen_to_order.url
    KITCHEN_TO_ORDER_NAME        = aws_sqs_queue.kitchen_to_order.name
    PAYMENT_TO_ORDER_QUEUE_URL   = aws_sqs_queue.payment_to_order.url
    PAYMENT_TO_ORDER_NAME        = aws_sqs_queue.payment_to_order.name
    ORDER_TO_PAYMENT_QUEUE_URL   = aws_sqs_queue.order_to_payment.url
    ORDER_TO_PAYMENT_NAME        = aws_sqs_queue.order_to_payment.name
    APPLICATION_PORT             = "8080"
  }
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

# outputs.tf da INFRA

output "oidc_provider_arn" {
  description = "ARN do OIDC Provider do EKS"
  value       = module.eks.oidc_provider_arn
}