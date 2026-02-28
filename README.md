# aws-platform

![OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.11-blue?logo=opentofu)
![Terragrunt](https://img.shields.io/badge/Terragrunt-latest-blue?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Platform-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

OpenTofu + Terragrunt monorepo for multi-tenant AWS platform infrastructure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  Organization Layer (management account)                            │
│  org-identity · org-security · org-compliance · org-cost            │
│  org-networking · org-scp                                           │
└─────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Environment Layer (dev / staging / production)                     │
│                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────────────────┐  │
│  │ network  │───▶│ cluster  │───▶│ druid · pipeline · llm       │  │
│  │          │    │          │───▶│ gateway · rag · mlops         │  │
│  │          │    │          │───▶│ governance · observability    │  │
│  │          │    │          │───▶│ secrets                       │  │
│  │          │    │          │───▶│ cluster-addons                │  │
│  │          │    │          │───▶│ cluster-bootstrap             │  │
│  └──────────┘    └──────────┘    └──────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ backup · break-glass · service-quotas · cost · dns           │  │
│  │ (standalone — no dependencies)                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

**Dependency chain:**

```
network → cluster ─┬─ druid*           (* also reads network outputs)
                   ├─ pipeline*
                   ├─ llm*
                   ├─ gateway
                   ├─ rag
                   ├─ mlops
                   ├─ governance
                   ├─ observability
                   ├─ secrets
                   ├─ cluster-addons
                   └─ cluster-bootstrap
```

**GitOps boundary:** OpenTofu deploys AWS resources + Cilium + ArgoCD. ArgoCD manages everything else via [aws-eks-gitops](https://github.com/stxkxs/aws-eks-gitops).

**State layout:**

```
s3://{account_id}-{region}-tfstate/{env}/{component}/terraform.tfstate
```

## Repository Structure

```
aws-platform/
├── components/              # OpenTofu root modules (24 components)
│   ├── network/             # VPC, subnets, NAT, VPC endpoints, flow logs
│   ├── cluster/             # EKS, Karpenter, Cilium, ArgoCD, IRSA, S3
│   ├── cluster-addons/      # Velero, OpenCost, KEDA, Argo Events/Workflows
│   ├── cluster-bootstrap/   # Cilium CNI + ArgoCD Helm bootstrap
│   ├── druid/               # Per-tenant Aurora, MSK, S3, IRSA
│   ├── pipeline/            # Per-tenant Batch, S3, SQS, IRSA
│   ├── gateway/             # Per-tenant API Gateway, WAF, Cognito, IRSA
│   ├── llm/                 # Per-tenant EFS, DynamoDB, SQS, S3, IRSA
│   ├── mlops/               # Per-tenant ML infrastructure
│   ├── rag/                 # Per-tenant RAG infrastructure
│   ├── governance/          # Per-tenant governance resources
│   ├── observability/       # SNS topics, CloudWatch alarms + dashboard
│   ├── secrets/             # KMS, Secrets Manager, External Secrets IRSA
│   ├── backup/              # AWS Backup plans, vault lock
│   ├── break-glass/         # Emergency access IAM roles + SNS alerts
│   ├── service-quotas/      # Service quota monitoring + alarms
│   ├── cost/                # Budgets, anomaly detection, CUR
│   ├── dns/                 # Route53 zones, ACM certs, DNSSEC
│   ├── org-identity/        # AWS SSO permission sets + assignments
│   ├── org-security/        # GuardDuty, Security Hub
│   ├── org-compliance/      # CloudTrail, Config, shared KMS
│   ├── org-cost/            # Org budgets, cost categories, CUR 2.0
│   ├── org-networking/      # Transit Gateway, IPAM, Route53 Resolver
│   └── org-scp/             # Service Control Policies
├── live/                    # Terragrunt environment configs
│   ├── terragrunt.hcl       # Root config (provider, remote state)
│   ├── _envcommon/          # Shared dependency + input wiring (24 .hcl)
│   ├── dev/                 # Development (18 components + env.hcl)
│   ├── staging/             # Staging
│   ├── production/          # Production
│   └── org/                 # Organization-level (6 components + env.hcl)
├── modules/
│   └── irsa/                # Shared IRSA role factory module
├── scripts/
│   └── init-backend.sh      # Creates S3 bucket for state
├── Makefile                 # Build automation
└── .tflint.hcl              # TFLint config (AWS plugin 0.34.0)
```

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.11.0
- [Terragrunt](https://terragrunt.gruntwork.io/) (latest)
- [AWS CLI](https://aws.amazon.com/cli/) v2, configured with credentials
- [TFLint](https://github.com/terraform-linters/tflint) with AWS plugin
- AWS account(s) with Organizations enabled
- OIDC provider for GitHub Actions (if using CI/CD workflows)

## Quick Start

```bash
# 1. Clone and configure
git clone <repo-url> && cd aws-platform
# Update account IDs in live/{dev,staging,production,org}/env.hcl

# 2. Create backend infrastructure
./scripts/init-backend.sh <account_id> <region>

# 3. Plan all components for dev
make plan ENVIRONMENT=dev

# 4. Apply
make apply ENVIRONMENT=dev

# 5. Single component
make plan ENVIRONMENT=dev COMPONENT=network
make apply ENVIRONMENT=dev COMPONENT=network
```

## Components Reference

### Organization-Level

Deployed once in the management account (`live/org/`).

| Component | Purpose | Key Resources |
|-----------|---------|---------------|
| **org-identity** | SSO access management | Permission sets (Admin, PowerUser, ReadOnly, PlatformEngineer, Developer), groups, account assignments |
| **org-security** | Threat detection | GuardDuty (S3, EKS, malware), Security Hub (CIS, AWS Foundational) |
| **org-compliance** | Audit infrastructure | Shared KMS key, CloudTrail, AWS Config |
| **org-cost** | Org-wide cost control | Cost categories, org budget, anomaly detection, CUR 2.0 export |
| **org-networking** | Cross-account networking | Transit Gateway, RAM share, IPAM, Route53 Resolver rules |
| **org-scp** | Guardrails | Service Control Policies attached to target OUs/accounts |

### Environment-Level

Deployed per environment (`live/{dev,staging,production}/`).

| Component | Purpose | Dependencies | Multi-Tenant |
|-----------|---------|--------------|:------------:|
| **network** | VPC, subnets, NAT, VPC endpoints, flow logs | — | |
| **cluster** | EKS, Karpenter, Cilium, ArgoCD, IRSA roles, S3 buckets | network | |
| **cluster-addons** | Velero, OpenCost, KEDA, Argo Events/Workflows IRSA | cluster | |
| **cluster-bootstrap** | Cilium CNI + ArgoCD Helm bootstrap | cluster | |
| **druid** | Apache Druid infra — Aurora MySQL, MSK, S3 | network, cluster | ✓ |
| **pipeline** | Batch pipelines — AWS Batch, S3 (raw/staging/curated), SQS | network, cluster | ✓ |
| **llm** | LLM serving — EFS, DynamoDB, SQS, S3 | network, cluster | ✓ |
| **gateway** | API layer — API Gateway v2, WAF, Cognito | cluster | ✓ |
| **mlops** | ML operations — SageMaker infrastructure | cluster | ✓ |
| **rag** | RAG infrastructure | cluster | ✓ |
| **governance** | Data governance resources | cluster | ✓ |
| **observability** | SNS (critical/warning/info), CloudWatch alarms + dashboard | cluster | |
| **secrets** | KMS key, Secrets Manager, External Secrets IRSA | cluster | |
| **backup** | AWS Backup plans, vault lock, notifications | — | |
| **break-glass** | Emergency IAM roles, SNS alerts, permissions boundary | — | |
| **service-quotas** | Service quota monitoring, CloudWatch alarms | — | |
| **cost** | Budgets, anomaly detection, CUR | — | |
| **dns** | Route53 zones, ACM certificates, DNSSEC | — | |

## Multi-Tenant Components

Seven components use a `tenants = {}` map variable to provision isolated resources per tenant. Each tenant gets its own set of AWS resources (databases, buckets, queues, IRSA roles, etc.) via `for_each`.

**Adding a tenant** — add an entry to the `tenants` map in the environment's terragrunt inputs:

```hcl
# live/staging/druid/terragrunt.hcl (inputs block)
tenants = {
  default = {
    rds_min_acu     = 0.5
    rds_max_acu     = 8
    msk_enabled     = true
  }
  analytics = {
    rds_min_acu     = 1
    rds_max_acu     = 16
    msk_enabled     = true
  }
}
```

Each multi-tenant component defines its own tenant schema with sensible defaults. See the `variables.tf` in each component for the full set of options.

## Environments

| | dev | staging | production | org |
|---|-----|---------|------------|-----|
| **NAT Gateways** | 1 | 2 | 3 | — |
| **Public API Access** | Yes | No | No | — |
| **VPC Flow Logs** | No | Yes | Yes | — |
| **Velero Backup** | No | Yes | Yes | — |
| **System Nodes** | 2 | 2–6 | 3–9 | — |
| **Cilium Replicas** | 1 | 2 | 2 | — |
| **ArgoCD Replicas** | 1 | 2 | 2 | — |
| **Druid RDS ACU** | 0.5–4 | 0.5–8 | 2–16 | — |
| **Druid MSK** | Disabled | Enabled | Enabled | — |

**Adding a new environment:** copy an existing directory (e.g. `live/dev/` → `live/sandbox/`), update `env.hcl` with the new account ID and environment name, and adjust inputs as needed.

## Makefile Targets

```
make fmt              Format all OpenTofu files
make fmt-check        Check formatting without modifying files
make validate         Validate all components (init + validate)
make lint             Run TFLint on all components
make plan             Plan for ENVIRONMENT (default: dev), use COMPONENT=<name>|all
make apply            Apply for ENVIRONMENT, use COMPONENT=<name>|all
make init-backend     Create S3 backend bucket for state
make help             Show all targets
```

**Examples:**

```bash
make plan ENVIRONMENT=production COMPONENT=cluster
make apply ENVIRONMENT=staging
make validate && make lint    # pre-commit checks
```

## CI/CD

Four GitHub Actions workflows, all using OpenTofu 1.11.5 + Terragrunt 0.99.4 + AWS OIDC auth.

### ci.yml — Pull Request Validation

Triggers on PRs to `main` and pushes to `main`.

| Job | What it does |
|-----|-------------|
| **fmt** | `tofu fmt -check` on components/ and modules/ |
| **validate** | `tofu init && tofu validate` per component (matrix of 24) |
| **tflint** | Recursive lint with AWS plugin |
| **checkov** | Security scan on components/ |
| **plan** | Terragrunt plan across envs × components (PRs only) |

### deploy.yml — Manual Deploy

Workflow dispatch with inputs: environment, component, action (plan/apply). Uses GitHub environment protection rules for approvals.

### destroy.yml — Manual Destroy

Workflow dispatch for dev/staging only (production excluded). Requires typing the environment name as confirmation. Runs `terragrunt destroy`.

### drift.yml — Drift Detection

Scheduled weekday runs (6 AM UTC, Mon–Fri) against production. Monitors 8 core components: `network`, `cluster`, `cluster-addons`, `cluster-bootstrap`, `dns`, `cost`, `observability`, `secrets`. Creates GitHub issues labelled `drift` when infrastructure has diverged from state.

### Setup

1. Create an IAM OIDC identity provider for GitHub Actions in your AWS account
2. Create a role with the necessary permissions and trust policy
3. Set `AWS_ROLE_ARN` as a GitHub Actions variable (per environment)

## State Management

- **Backend:** S3 with versioning and AES-256 encryption
- **Locking:** Native S3 conditional writes (OpenTofu 1.8+)
- **Key convention:** `{environment}/{component}/terraform.tfstate`
- **Bucket naming:** `{account_id}-{region}-tfstate`

Initialize the backend:

```bash
./scripts/init-backend.sh <account_id> <region>
```

This creates the S3 bucket (versioned, encrypted, public access blocked).

## Customization

**Change region** — update `region` in `live/{env}/env.hcl`. All components inherit it via the root `terragrunt.hcl`.

**Add a component** — see [CONTRIBUTING.md](CONTRIBUTING.md) for the full checklist.

**Remove a component** — delete the `live/{env}/<name>/` directory, the `live/_envcommon/<name>.hcl` file, and optionally the `components/<name>/` directory. Remove it from any CI matrices if referenced.

**Adjust SCPs** — modify `target_ids` in the org-scp component to control which OUs or accounts the policies apply to.

**Default tags** — all resources are tagged via the root provider config. Tags include `Environment`, `ManagedBy`, `Project`, `CostCenter`, `BusinessUnit`, `DataClassification`, `Compliance`, and `Repository`.

## Documentation

| Document | Description |
|----------|-------------|
| [Onboarding Guide](docs/onboarding.md) | New engineer setup, tool installation, codebase walkthrough |
| [Architecture](docs/architecture.md) | Design rationale, dependency graph, layer breakdown, security model |
| [Operations](docs/operations.md) | Day-to-day procedures, CI/CD details, tenant management |
| [Runbooks](docs/runbooks.md) | Step-by-step procedures for common operational scenarios |
| [Troubleshooting](docs/troubleshooting.md) | Common errors and their resolutions |
| [Contributing](CONTRIBUTING.md) | Development workflow, adding components/tenants/environments |
