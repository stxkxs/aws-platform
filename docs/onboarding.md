# Onboarding Guide

Welcome to aws-platform. This guide gets you from zero to your first `plan` output.

## What This Repo Does

This repo provisions and manages all AWS infrastructure for the platform: networking, EKS clusters, databases, queues, storage, IAM, monitoring, and cost controls. It uses OpenTofu for resource definitions and Terragrunt for environment orchestration.

**What it does NOT do:** in-cluster workloads (Kubernetes deployments, Helm releases beyond bootstrap). Those are managed by ArgoCD via the [aws-eks-gitops](https://github.com/stxkxs/aws-eks-gitops) repo.

## Tool Installation

| Tool | Version | Install |
|------|---------|---------|
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.11.0 | `brew install opentofu` |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | latest | `brew install terragrunt` |
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | v2 | `brew install awscli` |
| [TFLint](https://github.com/terraform-linters/tflint) | latest | `brew install tflint` |
| TFLint AWS plugin | 0.34.0 | `tflint --init` (reads `.tflint.hcl`) |

## AWS Access

Access is managed through AWS IAM Identity Center (SSO), configured by the `org-identity` component.

1. Get your SSO start URL and permission set from a platform engineer
2. Configure a profile:
   ```bash
   aws configure sso
   ```
3. Login:
   ```bash
   aws sso login --profile <your-profile>
   ```
4. Verify:
   ```bash
   aws sts get-caller-identity --profile <your-profile>
   ```

Set the profile as default or export `AWS_PROFILE` for Terragrunt to pick up.

## Verify Setup

Run the local validation suite — no AWS credentials needed:

```bash
make fmt-check && make validate && make lint
```

All three should pass. If `tflint` fails, make sure you ran `tflint --init` to install the AWS plugin.

## Your First Plan

```bash
make plan ENVIRONMENT=dev COMPONENT=network
```

This runs `terragrunt plan` for the network component in dev. You need valid AWS credentials for this step.

## Codebase Walkthrough

### `components/`

24 OpenTofu root modules, each self-contained with `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`. Seven multi-tenant components also have a `modules/tenant/` sub-module.

Components define **what** to create. They are environment-agnostic — no hardcoded account IDs, regions, or environment names.

### `live/`

Terragrunt configuration that wires components to environments.

- **`terragrunt.hcl`** (root) — generates the AWS provider with default tags and configures the S3 backend. Every environment inherits this.
- **`_envcommon/<name>.hcl`** — one per component. Declares dependencies (which other components' outputs this one needs) and shared inputs.
- **`{env}/env.hcl`** — environment-specific locals: `account_id`, `region`, `environment`, `cost_center`, `business_unit`, `data_classification`, `compliance`, `repository`.
- **`{env}/<component>/terragrunt.hcl`** — per-environment overrides (e.g., node counts, feature toggles, tenant maps).

### `modules/`

Shared sub-modules used across components:

- **`irsa/`** — IAM Roles for Service Accounts factory. Creates an IAM role with OIDC trust policy scoped to a specific Kubernetes namespace and service account.

### Key Files

- **`Makefile`** — build automation (`fmt`, `validate`, `lint`, `plan`, `apply`)
- **`.tflint.hcl`** — TFLint configuration (AWS plugin, naming/documentation rules)
- **`scripts/init-backend.sh`** — creates the S3 state bucket

## Key Concepts

### IRSA (IAM Roles for Service Accounts)

Pods in EKS assume IAM roles via OIDC federation. The `modules/irsa/` module creates these roles, scoped to a specific namespace and service account. Multi-tenant components create one IRSA role per tenant.

### Multi-Tenant Pattern

Seven components (`druid`, `pipeline`, `gateway`, `llm`, `mlops`, `rag`, `governance`) accept a `var.tenants` map. Each key becomes a separate set of AWS resources via `for_each`. Tenants are isolated at the AWS resource level (separate databases, buckets, queues, IAM roles).

### GitOps Boundary

OpenTofu manages AWS resources plus the initial bootstrap of Cilium (CNI) and ArgoCD (via `cluster-bootstrap`). Once ArgoCD is running, it takes over all in-cluster workload management from the `aws-eks-gitops` repo.

### Default Tags

The root `terragrunt.hcl` injects 8 tags on every resource: `Environment`, `ManagedBy`, `Project`, `CostCenter`, `BusinessUnit`, `DataClassification`, `Compliance`, `Repository`. Components must not duplicate these.

### State Management

Each component in each environment has its own state file in S3. Locking uses native S3 conditional writes (`use_lockfile = true`) — no DynamoDB table needed. State buckets are versioned and encrypted.

## Next Steps

- [Architecture](architecture.md) — design rationale, dependency graph, security model
- [Operations](operations.md) — day-to-day procedures, CI/CD details
