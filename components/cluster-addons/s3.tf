################################################################################
# Addon S3 Buckets
################################################################################

# Velero backup storage (conditional)
module "velero_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  count   = var.velero_enabled ? 1 : 0

  bucket = "${local.bucket_prefix}-velero"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "cleanup"
      enabled = true
      expiration = {
        days = var.environment == "production" ? 90 : 30
      }
    },
  ]

  attach_deny_insecure_transport_policy = true

  tags = local.tags
}

# Loki log storage
module "loki_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.bucket_prefix}-loki"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "cleanup"
      enabled = true
      expiration = {
        days = var.environment == "production" ? 90 : (var.environment == "staging" ? 30 : 14)
      }
    },
  ]

  attach_deny_insecure_transport_policy = true

  tags = local.tags
}

# Tempo trace storage
module "tempo_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.bucket_prefix}-tempo"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "cleanup"
      enabled = true
      expiration = {
        days = var.environment == "production" ? 30 : 7
      }
    },
  ]

  attach_deny_insecure_transport_policy = true

  tags = local.tags
}

# Argo Workflows artifact storage (conditional)
module "argo_workflows_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  count   = var.argo_workflows_enabled ? 1 : 0

  bucket = "${local.bucket_prefix}-argo-workflows"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "cleanup"
      enabled = true
      expiration = {
        days = 30
      }
    },
  ]

  attach_deny_insecure_transport_policy = true

  tags = local.tags
}
