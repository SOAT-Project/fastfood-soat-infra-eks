# variables.tf

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

################################################################################
# RDS Variables
################################################################################

variable "rds_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Storage alocado para o RDS em GB"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "17.2"
}

variable "rds_database_name" {
  description = "Nome do database"
  type        = string
  default     = "fastfood"
}

variable "rds_username" {
  description = "Username do RDS"
  type        = string
  default     = "postgres"
}

variable "rds_backup_retention_period" {
  description = "Período de retenção de backup em dias"
  type        = number
  default     = 7
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot ao deletar RDS"
  type        = bool
  default     = true
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ"
  type        = bool
  default     = false
}

################################################################################
# SQS Variables
################################################################################

variable "sqs_visibility_timeout" {
  description = "Visibility timeout das filas SQS em segundos"
  type        = number
  default     = 300
}

variable "sqs_message_retention" {
  description = "Tempo de retenção de mensagens em segundos (4 dias)"
  type        = number
  default     = 345600
}

variable "sqs_dlq_retention" {
  description = "Tempo de retenção de mensagens na DLQ em segundos (14 dias)"
  type        = number
  default     = 1209600
}

variable "sqs_max_receive_count" {
  description = "Número máximo de tentativas antes de ir pra DLQ"
  type        = number
  default     = 3
}

################################################################################
# Application Variables
################################################################################

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "kubernetes_namespace" {
  description = "Namespace do K8s para o fastfood app"
  type        = string
  default     = "fastfood"
}