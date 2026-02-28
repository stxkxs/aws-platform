data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  tags = merge(var.tags, {
    Component = "backup"
    Team      = var.team
  })
}

################################################################################
# KMS Key for Backup Vault Encryption
################################################################################

resource "aws_kms_key" "backup" {
  description             = "KMS key for AWS Backup vault encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.environment}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

################################################################################
# Backup Vault
################################################################################

resource "aws_backup_vault" "this" {
  name        = "${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn

  tags = local.tags
}

resource "aws_backup_vault_lock_configuration" "this" {
  count = var.enable_vault_lock ? 1 : 0

  backup_vault_name   = aws_backup_vault.this.name
  changeable_for_days = 3
  max_retention_days  = 365
  min_retention_days  = 1
}

################################################################################
# Backup Plans
################################################################################

resource "aws_backup_plan" "this" {
  for_each = var.backup_plans

  name = "${var.environment}-${each.key}"

  rule {
    rule_name         = each.key
    target_vault_name = aws_backup_vault.this.name
    schedule          = each.value.schedule

    lifecycle {
      delete_after       = each.value.retention_days
      cold_storage_after = each.value.cold_storage_after
    }

    dynamic "copy_action" {
      for_each = each.value.copy_action != null ? [each.value.copy_action] : []
      content {
        destination_vault_arn = copy_action.value.destination_vault_arn
        lifecycle {
          delete_after = copy_action.value.retention_days
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# Backup Selection (tag-based)
################################################################################

resource "aws_backup_selection" "this" {
  for_each = var.backup_plans

  name         = "${var.environment}-${each.key}"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this[each.key].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupPolicy"
    value = each.key
  }
}

################################################################################
# IAM Role for AWS Backup
################################################################################

resource "aws_iam_role" "backup" {
  name = "${var.environment}-aws-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

################################################################################
# Notifications
################################################################################

resource "aws_sns_topic" "backup_notifications" {
  name = "${var.environment}-backup-notifications"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "backup_email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_backup_vault_notifications" "this" {
  backup_vault_name   = aws_backup_vault.this.name
  sns_topic_arn       = aws_sns_topic.backup_notifications.arn
  backup_vault_events = ["BACKUP_JOB_FAILED", "BACKUP_JOB_EXPIRED", "RESTORE_JOB_FAILED"]
}

################################################################################
# SSM Parameters
################################################################################

resource "aws_ssm_parameter" "vault_arn" {
  name  = "/${var.environment}/backup/vault-arn"
  type  = "String"
  value = aws_backup_vault.this.arn

  tags = local.tags
}
