# aws-platform

OpenTofu + Terragrunt monorepo for multi-tenant AWS platform infrastructure.

## Build & Validate

```bash
make fmt              # format all .tf files
make fmt-check        # check formatting (CI uses this)
make validate         # init + validate every component
make lint             # tflint with AWS plugin
make plan ENVIRONMENT=dev COMPONENT=network   # plan one component
make apply ENVIRONMENT=staging                # apply all components in env
```

## Architecture

- **24 components** across 4 environments (dev, staging, production, org)
- **Dependency chain:** `network → cluster → {druid, pipeline, llm, gateway, rag, mlops, governance, observability, secrets, cluster-addons, cluster-bootstrap}`
- `cost`, `dns`, `backup`, `break-glass`, and `service-quotas` are standalone (no dependencies)
- `org-*` components deploy to the management account only
- **GitOps boundary:** OpenTofu deploys AWS resources + Cilium + ArgoCD. ArgoCD manages in-cluster workloads via [aws-eks-gitops](https://github.com/stxkxs/aws-eks-gitops)

## Conventions

- OpenTofu >= 1.8.0, not Terraform — use `tofu` CLI, never `terraform`
- All HCL files: `tofu fmt` style (2-space indent, aligned `=`)
- Component variables must have descriptions (enforced by tflint `terraform_documented_variables`)
- Component outputs must have descriptions (enforced by tflint `terraform_documented_outputs`)
- Snake_case for all resource names and variables (enforced by tflint `terraform_naming_convention`)
- Default tags (Environment, ManagedBy, Project) are injected by root terragrunt.hcl — do not duplicate in components
- Every component lives in `components/<name>/` with its own `versions.tf`
- Dependency wiring lives in `live/_envcommon/<name>.hcl`, not in the component itself
- Environment-specific overrides go in `live/{env}/{component}/terragrunt.hcl`
- State path: `s3://{account}-{region}-tfstate/{env}/{component}/terraform.tfstate` (native S3 locking via `use_lockfile`)

## Multi-Tenant Pattern

7 components use `var.tenants = map(object({...}))` with `for_each`:
druid, pipeline, gateway, llm, mlops, rag, governance.

Each tenant gets isolated AWS resources (databases, buckets, queues, IRSA roles).
Tenant modules live in `components/<name>/modules/tenant/`.

## File Structure

```
components/<name>/       # OpenTofu root modules
  main.tf                # primary resources
  variables.tf           # inputs (all documented)
  outputs.tf             # outputs (all documented)
  versions.tf            # required_providers + required_version
  modules/tenant/        # sub-module for multi-tenant components
live/
  terragrunt.hcl         # root config (provider, remote_state)
  _envcommon/<name>.hcl  # dependency wiring + shared inputs
  {env}/env.hcl          # account_id, region, environment
  {env}/<component>/     # terragrunt.hcl with env-specific inputs
modules/irsa/            # shared IRSA role factory
```

## Testing Changes

1. `make fmt-check` — formatting
2. `make validate` — syntax + provider validation
3. `make lint` — tflint rules
4. `make plan ENVIRONMENT=dev COMPONENT=<name>` — dry-run against dev

## CI/CD

- `ci.yml` — PRs: fmt, validate, tflint, checkov (security scan), plan matrix
- `deploy.yml` — manual dispatch: plan or apply, uses GitHub environment protection
- `destroy.yml` — manual dispatch: dev/staging only, requires confirmation string
- `drift.yml` — scheduled weekday drift detection on production, creates GitHub issues
- Auth: AWS OIDC via `AWS_ROLE_ARN` GitHub Actions variable
