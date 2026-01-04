# sqs.tf

################################################################################
# SQS Queues
################################################################################

# FIFO: order-to-kitchen
resource "aws_sqs_queue" "order_to_kitchen_dlq" {
  name                        = "${local.name}-order-to-kitchen-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.sqs_dlq_retention

  tags = merge(local.tags, {
    Name        = "${local.name}-order-to-kitchen-dlq"
    Environment = var.environment
  })
}

resource "aws_sqs_queue" "order_to_kitchen" {
  name                        = "${local.name}-order-to-kitchen.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = var.sqs_visibility_timeout
  message_retention_seconds   = var.sqs_message_retention

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_to_kitchen_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = merge(local.tags, {
    Name        = "${local.name}-order-to-kitchen"
    Environment = var.environment
  })
}

# STANDARD: kitchen-to-order (única standard!)
resource "aws_sqs_queue" "kitchen_to_order_dlq" {
  name                      = "${local.name}-kitchen-to-order-dlq"
  message_retention_seconds = var.sqs_dlq_retention

  tags = merge(local.tags, {
    Name        = "${local.name}-kitchen-to-order-dlq"
    Environment = var.environment
  })
}

resource "aws_sqs_queue" "kitchen_to_order" {
  name                       = "${local.name}-kitchen-to-order"
  visibility_timeout_seconds = var.sqs_visibility_timeout
  message_retention_seconds  = var.sqs_message_retention

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.kitchen_to_order_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = merge(local.tags, {
    Name        = "${local.name}-kitchen-to-order"
    Environment = var.environment
  })
}

# FIFO: payment-to-order
resource "aws_sqs_queue" "payment_to_order_dlq" {
  name                        = "${local.name}-payment-to-order-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.sqs_dlq_retention

  tags = merge(local.tags, {
    Name        = "${local.name}-payment-to-order-dlq"
    Environment = var.environment
  })
}

resource "aws_sqs_queue" "payment_to_order" {
  name                        = "${local.name}-payment-to-order.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = var.sqs_visibility_timeout
  message_retention_seconds   = var.sqs_message_retention

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_to_order_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = merge(local.tags, {
    Name        = "${local.name}-payment-to-order"
    Environment = var.environment
  })
}

# FIFO: order-to-payment
resource "aws_sqs_queue" "order_to_payment_dlq" {
  name                        = "${local.name}-order-to-payment-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = var.sqs_dlq_retention

  tags = merge(local.tags, {
    Name        = "${local.name}-order-to-payment-dlq"
    Environment = var.environment
  })
}

resource "aws_sqs_queue" "order_to_payment" {
  name                        = "${local.name}-order-to-payment.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = var.sqs_visibility_timeout
  message_retention_seconds   = var.sqs_message_retention

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_to_payment_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = merge(local.tags, {
    Name        = "${local.name}-order-to-payment"
    Environment = var.environment
  })
}

################################################################################
# IAM Policy para acesso ao SQS
################################################################################

resource "aws_iam_policy" "fastfood_sqs_policy" {
  name        = "${local.name}-sqs-policy"
  description = "Policy para acesso às filas SQS do fastfood"

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
          aws_sqs_queue.payment_to_order.arn,
          aws_sqs_queue.order_to_payment.arn,
          aws_sqs_queue.order_to_kitchen_dlq.arn,
          aws_sqs_queue.kitchen_to_order_dlq.arn,
          aws_sqs_queue.payment_to_order_dlq.arn,
          aws_sqs_queue.order_to_payment_dlq.arn
        ]
      }
    ]
  })

  tags = merge(local.tags, {
    Environment = var.environment
  })
}