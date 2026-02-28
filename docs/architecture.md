# Architecture

Design decisions, dependency graph, and structural overview of the aws-platform infrastructure.

## Design Rationale

### Why OpenTofu (not Terraform)

OpenTofu is the open-source fork of Terraform, free from licensing restrictions. The codebase requires `>= 1.11.0` and uses native S3 state locking (`use_lockfile`), removing the need for a DynamoDB lock table.

### Why Terragrunt

Terragrunt provides DRY environment management on top of OpenTofu:
- **Single provider/backend config** — the root `terragrunt.hcl` generates `provider.tf` and `backend.tf` for every component
- **Dependency orchestration** — `dependency` blocks in `_envcommon/` wire outputs between components without hardcoding
- **Environment parity** — same components, different inputs per environment

### Why Components (not a Monolith)

Each component has independent state, independent plan/apply, and independent blast radius. A failed `gateway` apply does not block `observability`. Components can be deployed in parallel where dependencies allow.

### Why Multi-Tenant via `for_each`

The `for_each` pattern over a `tenants` map gives each tenant isolated AWS resources while sharing the same OpenTofu module code. Adding a tenant is a map entry, not a new module call. Resources are named with the tenant key, making them easy to identify and delete.

## Dependency Graph

```
                    ┌──────────┐
                    │ network  │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │ cluster  │
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼─────┐   ┌─────▼──────┐  ┌─────▼──────────┐
    │  druid*  │   │  gateway   │  │ cluster-addons  │
    │pipeline* │   │    rag     │  │cluster-bootstrap│
    │  llm*    │   │   mlops    │  └─────────────────┘
    └──────────┘   │ governance │
                   │observability│
                   │  secrets   │
                   └────────────┘

  * = also depends on network (vpc_id, private_subnet_ids)

  Standalone (no dependencies):
  backup · break-glass · service-quotas · cost · dns

  Organization layer (management account only):
  org-identity · org-security · org-compliance
  org-cost · org-networking · org-scp
```

### Dependency Details

| Component | Depends On | Receives |
|-----------|-----------|----------|
| **network** | — | — |
| **cluster** | network | vpc_id, private_subnet_ids, public_subnet_ids |
| **cluster-addons** | cluster | cluster_name, oidc_provider_arn, oidc_issuer |
| **cluster-bootstrap** | cluster | cluster_name, cluster_endpoint, cluster_certificate_authority_data |
| **druid** | network, cluster | vpc_id, private_subnet_ids, cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **pipeline** | network, cluster | vpc_id, private_subnet_ids, cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **llm** | network, cluster | vpc_id, private_subnet_ids, cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **gateway** | cluster | cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **rag** | cluster | cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **mlops** | cluster | cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **governance** | cluster | cluster_sg_id, oidc_provider_arn, oidc_issuer |
| **observability** | cluster | cluster_name |
| **secrets** | cluster | oidc_provider_arn, oidc_issuer |
| **backup** | — | — |
| **break-glass** | — | — |
| **service-quotas** | — | — |
| **cost** | — | — |
| **dns** | — | — |

## Layer Breakdown

### Organization Layer

Six components deployed once in the management account (`live/org/`). These establish cross-account governance and shared infrastructure.

| Component | Purpose |
|-----------|---------|
| **org-identity** | AWS IAM Identity Center (SSO) — permission sets (Admin, PowerUser, ReadOnly, PlatformEngineer, Developer), groups, account assignments |
| **org-security** | GuardDuty with S3/EKS/malware/RDS/Lambda detection, Security Hub with CIS and AWS Foundational standards |
| **org-compliance** | Shared KMS key, organization CloudTrail, AWS Config with rules and conformance packs |
| **org-cost** | Organization budget, cost categories, anomaly detection, Compute Optimizer, Savings Plans alarm, CUR 2.0 export |
| **org-networking** | Transit Gateway with RAM sharing, IPAM for centralized CIDR management, Route53 Resolver rules |
| **org-scp** | Service Control Policies attached to target OUs/accounts |

### Network Layer

**Component:** `network`

Provisions the VPC foundation for each environment:
- VPC with configurable CIDR
- 3 subnet tiers: public, private, intra (across configurable AZs)
- NAT gateways (1 in dev, 2 in staging, 3 in production)
- VPC endpoints for AWS services (optional)
- VPC flow logs (staging and production only)

### Cluster Layer

**Components:** `cluster`, `cluster-bootstrap`, `cluster-addons`

- **cluster** — EKS control plane, Karpenter for node autoscaling, system node group, access entries, S3 buckets for cluster artifacts
- **cluster-bootstrap** — Helm-based bootstrap of Cilium CNI and ArgoCD. This is the GitOps boundary — after bootstrap, ArgoCD manages in-cluster workloads from `aws-eks-gitops`
- **cluster-addons** — IRSA roles for optional cluster tools: Velero (backup), OpenCost, KEDA (autoscaling), Argo Events, Argo Workflows

### Workload Layer

Seven multi-tenant components, each accepting a `var.tenants` map:

| Component | Per-Tenant Resources | Team |
|-----------|---------------------|------|
| **druid** | Aurora MySQL (Serverless v2), MSK cluster, S3 buckets, Secrets Manager, SSM parameters, IRSA | data-platform |
| **pipeline** | AWS Batch compute, S3 data lake (raw/staging/curated), Glue catalog, MSK, Step Functions, IRSA | data-platform |
| **gateway** | API Gateway v2, WAF with bot control, Cognito user pool, usage plans, IRSA | platform |
| **llm** | EFS storage, DynamoDB, SQS queues, S3 model storage, ECR, Secrets Manager, IRSA | ml-platform |
| **mlops** | DynamoDB tables, ECR repos, S3 (datasets/artifacts), SQS, IRSA | ml-platform |
| **rag** | OpenSearch Serverless, S3 document storage, DynamoDB (conversations), IRSA | ml-platform |
| **governance** | S3 audit/guardrail buckets, DynamoDB, EventBridge, IRSA | security |

### Operational Layer

| Component | Purpose | Team |
|-----------|---------|------|
| **observability** | SNS topics (critical/warning/info), CloudWatch alarms (CPU, memory, node count, API errors), dashboard | sre |
| **secrets** | KMS key with rotation, Secrets Manager entries, External Secrets Operator IRSA | security |
| **backup** | AWS Backup plans with configurable schedules/retention, vault lock for production, email notifications | sre |
| **break-glass** | Emergency IAM roles with trust policy, SNS alerts on assumption, optional permissions boundary | security |
| **service-quotas** | CloudWatch alarms for AWS service quotas (VPCs, EIPs, NAT gateways, EKS clusters, Lambda concurrency) | platform |
| **cost** | Budget alerts, anomaly detection, Cost and Usage Reports, per-tenant anomaly detection | finops |
| **dns** | Route53 hosted zones, subdomain delegation, ACM certificates, DNSSEC | platform |

## Environment Differentiation

| Setting | dev | staging | production |
|---------|-----|---------|------------|
| NAT gateways | 1 | 2 | 3 (HA) |
| VPC flow logs | Off | On | On |
| Cluster public API | Yes | No | No |
| System node range | 2 | 2–6 | 3–9 |
| System node disk | 50 GB | 100 GB | 100 GB |
| Cilium operator replicas | 1 | 2 | 2 |
| ArgoCD replicas | 1 | 2 | 2 |
| Druid RDS ACU range | 0.5–4 | 0.5–8 | 2–16 |
| Druid MSK | Disabled | Enabled | Enabled |
| Druid deletion protection | Off | On | On |
| Druid backup retention | 3 days | 7 days | 35 days |
| Data classification | internal | internal | confidential |

## GitOps Boundary

```
┌─────────────────────────────────┐     ┌─────────────────────────────┐
│         aws-platform            │     │       aws-eks-gitops        │
│         (this repo)             │     │                             │
│                                 │     │                             │
│  OpenTofu + Terragrunt          │     │  ArgoCD ApplicationSets    │
│                                 │     │                             │
│  Manages:                       │     │  Manages:                   │
│  · AWS resources (VPC, EKS,     │     │  · Kubernetes workloads     │
│    RDS, S3, IAM, etc.)          │     │  · Helm releases            │
│  · Cilium CNI (bootstrap)       │     │  · ConfigMaps, Secrets      │
│  · ArgoCD (bootstrap)           │     │  · Ingress, Services        │
│  · IRSA roles for pods          │     │  · CRDs, Operators          │
└─────────────────────────────────┘     └─────────────────────────────┘
              │                                       │
              │         cluster-bootstrap             │
              │◄─────── is the handoff point ────────►│
              │                                       │
```

After `cluster-bootstrap` deploys Cilium and ArgoCD, ArgoCD watches the `aws-eks-gitops` repo and reconciles all in-cluster resources.

## Security Model

### CI/CD Authentication

GitHub Actions authenticates to AWS via OIDC federation — no long-lived credentials. Each environment has its own `AWS_ROLE_ARN` with a trust policy scoped to the repository.

### Pod Authentication (IRSA)

Pods authenticate to AWS services via IAM Roles for Service Accounts. The `modules/irsa/` factory creates roles with OIDC trust policies scoped to specific namespaces and service accounts. Multi-tenant components create one IRSA role per tenant.

### Guardrails (SCPs)

The `org-scp` component attaches Service Control Policies to OUs and accounts, preventing actions like disabling CloudTrail, leaving the organization, or using unapproved regions.

### Emergency Access

The `break-glass` component provisions IAM roles that can be assumed during incidents. Role assumption triggers SNS notifications. Sessions are time-limited (`max_session_duration`, default 1 hour).

### SSO Permission Sets

The `org-identity` component manages 5 permission sets with varying privilege levels. Access is assigned through groups and account mappings.

## State Management

- **Backend:** S3 with versioning and AES-256 encryption
- **Locking:** Native S3 conditional writes (`use_lockfile = true`) — no DynamoDB needed
- **Bucket naming:** `{account_id}-{region}-tfstate`
- **Key convention:** `{environment}/{component}/terraform.tfstate`
- **Initialization:** `./scripts/init-backend.sh <account_id> <region>` creates the bucket with versioning, encryption, and public access blocked

Each component in each environment has independent state, enabling parallel operations and isolated blast radius.

## Team Ownership

Based on `team` tags set in `_envcommon/` files:

| Team | Components |
|------|-----------|
| **platform** | network, cluster, cluster-addons, cluster-bootstrap, gateway, dns, service-quotas, all org-* |
| **sre** | observability, backup |
| **security** | governance, secrets, break-glass |
| **data-platform** | druid, pipeline |
| **ml-platform** | llm, mlops, rag |
| **finops** | cost |
