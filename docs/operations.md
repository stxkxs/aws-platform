# Operations

Day-to-day procedures for operating the aws-platform infrastructure.

## Planning and Applying

### Single Component

```bash
make plan ENVIRONMENT=dev COMPONENT=network
make apply ENVIRONMENT=dev COMPONENT=network
```

### All Components in an Environment

```bash
make plan ENVIRONMENT=dev
make apply ENVIRONMENT=dev
```

Terragrunt resolves the dependency graph and runs components in the correct order.

### Organization Components

```bash
make plan ENVIRONMENT=org COMPONENT=org-identity
make apply ENVIRONMENT=org COMPONENT=org-identity
```

## Deployment Order

For a from-scratch deployment, components must be applied in dependency order.

### Organization (run first, once)

```
1. org-scp
2. org-identity
3. org-security
4. org-compliance
5. org-cost
6. org-networking
```

Order within the org layer is flexible — these components have no inter-dependencies.

### Per Environment (dev → staging → production)

```
1. network
2. cluster
3. cluster-bootstrap          (depends on cluster)
4. cluster-addons             (depends on cluster)
5. secrets                    (depends on cluster)
6. observability              (depends on cluster)
7. druid                      (depends on network + cluster)
8. pipeline                   (depends on network + cluster)
9. llm                        (depends on network + cluster)
10. gateway                   (depends on cluster)
11. rag                       (depends on cluster)
12. mlops                     (depends on cluster)
13. governance                (depends on cluster)
14. cost                      (standalone)
15. dns                       (standalone)
16. backup                    (standalone)
17. break-glass               (standalone)
18. service-quotas            (standalone)
```

Steps 3–13 can run in parallel within their dependency tier. Steps 14–18 can run at any time.

Using `make apply ENVIRONMENT=dev` (without `COMPONENT`) runs `terragrunt run-all apply`, which handles ordering automatically.

## CI/CD Workflows

### ci.yml — Pull Request Validation

**Triggers:** PRs to `main`, pushes to `main`.

| Job | Details |
|-----|---------|
| **fmt** | Runs `tofu fmt -check -recursive` on `components/` and `modules/`. Fails if any file is unformatted. |
| **validate** | Matrix of all 24 components. Runs `tofu init -backend=false` then `tofu validate`. Catches syntax errors and missing variable definitions. |
| **tflint** | Runs TFLint recursively with the AWS plugin. Enforces naming conventions, documented variables/outputs, and AWS-specific rules. |
| **checkov** | Security scan on `components/`. Skips `CKV_AWS_144` (cross-region replication) and `CKV_AWS_145` (KMS encryption). |
| **plan** | PRs only. Matrix of 60 combinations: 18 workload components × 3 environments (54) + 6 org components × org (6). Runs `terragrunt plan` to show what would change. |

### deploy.yml — Manual Deploy

**Trigger:** Workflow dispatch (manual).

**Inputs:**
- `environment` — dev, staging, or production
- `component` — specific component name or "all"
- `action` — plan or apply

Uses GitHub environment protection rules — production requires approval. When `component=all`, runs `terragrunt run-all <action>`. Otherwise targets the specific component directory.

### destroy.yml — Manual Destroy

**Trigger:** Workflow dispatch (manual).

**Inputs:**
- `environment` — dev or staging only (production excluded)
- `component` — specific component name or "all"
- `confirm` — must exactly match the environment name

The confirmation guard (`confirm == environment`) prevents accidental destroys. Runs `terragrunt destroy` or `terragrunt run-all destroy`.

### drift.yml — Drift Detection

**Trigger:** Cron schedule, 6 AM UTC Monday–Friday. Also supports manual dispatch.

**Scope:** Production environment, 8 components: `network`, `cluster`, `cluster-addons`, `cluster-bootstrap`, `dns`, `cost`, `observability`, `secrets`.

**Behavior:** Runs `terragrunt plan -detailed-exitcode` for each component. Exit code 2 means changes detected (drift). When drift is found, creates or updates a GitHub issue labelled `drift` with the plan output.

**Response:** See [RB-001: Drift Detected](runbooks.md#rb-001-drift-detected) in the runbooks.

## Tenant Management

### Adding a Tenant

1. Identify the component(s) the tenant needs (e.g., `druid`, `pipeline`, `gateway`)
2. Edit the environment's `terragrunt.hcl` for each component
3. Add an entry to the `tenants` map:
   ```hcl
   tenants = {
     new-tenant = {
       # see variables.tf for the full schema and defaults
       deletion_protection = true
     }
   }
   ```
4. Plan to verify: `make plan ENVIRONMENT=<env> COMPONENT=<component>`
5. Apply: `make apply ENVIRONMENT=<env> COMPONENT=<component>`

### Removing a Tenant

1. Set `deletion_protection = false` and apply (for components that support it)
2. Remove the tenant entry from the `tenants` map
3. Plan and verify the destroy actions
4. Apply

### Tenant Configuration Reference

Each multi-tenant component has different tenant fields. Check the `variables.tf` in the component for the full schema:

| Component | Key Tenant Fields |
|-----------|------------------|
| **druid** | `rds_min_acu`, `rds_max_acu`, `rds_backup_days`, `msk_enabled`, `deletion_protection` |
| **pipeline** | `batch_enabled`, `step_functions_enabled`, `msk_enabled`, `batch_max_vcpus`, `deletion_protection` |
| **gateway** | `waf_enabled`, `cognito_enabled`, `waf_rate_limit`, `throttle_rate/burst/quota` |
| **llm** | `efs_performance_mode`, `sqs_visibility_timeout`, `dynamodb_pitr`, `deletion_protection` |
| **mlops** | `ecr_enabled`, `point_in_time_recovery`, `run_ttl_days`, `deletion_protection` |
| **rag** | `opensearch_standby_replicas`, `opensearch_dimensions`, `document_versioned`, `deletion_protection` |
| **governance** | `object_lock_enabled`, `event_bridge_enabled`, `point_in_time_recovery`, `deletion_protection` |

## Monitoring and Alerting

### CloudWatch Alarms (observability)

The `observability` component creates CloudWatch alarms for:
- **CPU utilization** — threshold configurable via `alarm_config`
- **Memory utilization** — threshold configurable
- **Node count** — minimum threshold
- **API server errors** — error rate threshold

Alarms publish to 3 SNS topics by severity: `critical`, `warning`, `info`. Subscribe team emails via `alert_email_endpoints` or a Slack webhook via `slack_webhook_url`.

### Budget Alerts (cost)

The `cost` component creates AWS Budget alerts at configurable thresholds (e.g., 50%, 80%, 100% of `monthly_budget_limit`). Anomaly detection creates alerts when spending patterns deviate. Notifications go to `budget_alert_emails`.

### Quota Alerts (service-quotas)

The `service-quotas` component monitors AWS service limits and creates CloudWatch alarms when usage exceeds `quota_threshold_percent` (default 80%). Monitored quotas include VPCs per region, EIPs, NAT gateways, EKS clusters, and Lambda concurrent executions.

### Drift Detection (drift.yml)

Production infrastructure is checked for drift every weekday morning. Drift issues appear in GitHub with the `drift` label. See the CI/CD section above for details.

## Secrets Management

The `secrets` component manages the encryption and secrets infrastructure:

1. **KMS key** — customer-managed key with automatic rotation (`enable_key_rotation`), configurable deletion window
2. **Secrets Manager** — secrets defined via the `secrets` map variable, organized under `secret_path_prefix`
3. **External Secrets IRSA** — IAM role for the External Secrets Operator pod, allowing it to read from Secrets Manager and write to Kubernetes Secrets

The flow: secrets are stored in AWS Secrets Manager → External Secrets Operator (running in EKS, authenticated via IRSA) syncs them → Kubernetes Secrets are created for pod consumption.

## Backup and Recovery

The `backup` component manages AWS Backup:

- **Backup plans** — configurable via the `backup_plans` map (schedule, retention, cold storage transition, cross-region copy)
- **Vault lock** — enabled for production environments to prevent backup deletion (compliance mode)
- **Notifications** — email alerts for backup job events via `notification_emails`
- **KMS** — backups encrypted with a dedicated KMS key

### Restore Procedure

1. Open the AWS Backup console in the target account/region
2. Navigate to the backup vault and find the recovery point
3. Select "Restore" and configure the target resource settings
4. Monitor the restore job in the AWS Backup console

For state file recovery, see [RB-004: Failed Apply](runbooks.md#rb-004-failed-apply--partial-state) in the runbooks.
