# fastfood-soat-infra-eks/infra/terraform/irsa.tf

################################################################################
# IAM Policies - Order Service
################################################################################

resource "aws_iam_policy" "order_service_sqs" {
  name        = "${local.name}-order-service-sqs"
  description = "Policy para o order-service acessar filas SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.order_to_kitchen.arn,
          aws_sqs_queue.kitchen_to_order.arn,
          aws_sqs_queue.order_to_payment.arn,
          aws_sqs_queue.payment_to_order.arn
        ]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "order_service_secrets" {
  name        = "${local.name}-order-service-secrets"
  description = "Policy para o order-service acessar secrets do RDS"

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

  tags = local.tags
}

################################################################################
# IRSA Role - Order Service
################################################################################

module "order_service_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name}-order-service"

  role_policy_arns = {
    sqs     = aws_iam_policy.order_service_sqs.arn
    secrets = aws_iam_policy.order_service_secrets.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["fastfood-orderservice:fastfood-orderservice-sa"]
    }
  }

  tags = local.tags
}