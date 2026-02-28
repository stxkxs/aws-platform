################################################################################
# ECR Repository (conditional)
################################################################################

resource "aws_ecr_repository" "this" {
  count = var.tenant_config.ecr_enabled ? 1 : 0

  name                 = "mlops/${var.environment}/${var.tenant_id}"
  image_tag_mutability = "MUTABLE"
  force_delete         = !var.tenant_config.deletion_protection

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.this.arn
  }

  tags = local.tenant_tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.tenant_config.ecr_enabled ? 1 : 0

  repository = aws_ecr_repository.this[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 50 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 50
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}
