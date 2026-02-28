# Contributing

Guide for developing and extending the aws-platform infrastructure.

## Prerequisites

Complete the [Onboarding Guide](docs/onboarding.md) first — tool installation, AWS access, and codebase orientation.

## Development Workflow

1. **Branch** — create a feature branch from `main`
2. **Validate locally** — `make fmt-check && make validate && make lint`
3. **Plan against dev** — `make plan ENVIRONMENT=dev COMPONENT=<name>`
4. **Open a PR** — CI runs fmt, validate, tflint, checkov, and plan matrix
5. **Review** — get approval, verify plan output in CI
6. **Merge** — deploy via `deploy.yml` workflow dispatch

## Adding a New Component

1. Create `components/<name>/` with these files:
   - `main.tf` — primary resources
   - `variables.tf` — inputs (all must have `description`, enforced by tflint)
   - `outputs.tf` — outputs (all must have `description`, enforced by tflint)
   - `versions.tf` — `required_version` and `required_providers`

2. Use snake_case for all resource names and variables (enforced by tflint `terraform_naming_convention`).

3. Do **not** add default tags (`Environment`, `ManagedBy`, `Project`, etc.) — they are injected by the root `terragrunt.hcl`.

4. Create `live/_envcommon/<name>.hcl` with:
   - `terraform` block pointing to `components/<name>/`
   - `dependency` blocks for any upstream components
   - `inputs` block wiring dependency outputs to variables

5. Create `live/{env}/<name>/terragrunt.hcl` for each target environment:
   ```hcl
   include "root" {
     path = find_in_parent_folders()
   }

   include "envcommon" {
     path   = "${dirname(find_in_parent_folders())}/_envcommon/<name>.hcl"
     expose = true
   }

   inputs = {
     # environment-specific overrides here
   }
   ```

6. Add the component to CI workflow matrices:
   - `ci.yml` — add to the validate and plan matrices
   - `deploy.yml` — add to the component allowlist
   - `destroy.yml` — add to the component allowlist

7. Update `README.md` — add a row to the Components Reference table.

## Adding a Multi-Tenant Component

Follow the standard component steps above, plus:

1. Create `components/<name>/modules/tenant/` sub-module with its own `variables.tf` and `outputs.tf`.

2. Define a `tenants` variable in the root module:
   ```hcl
   variable "tenants" {
     description = "Map of tenant configurations"
     type = map(object({
       # tenant-specific fields with defaults
     }))
     default = {}
   }
   ```

3. Instantiate the tenant module with `for_each`:
   ```hcl
   module "tenant" {
     source   = "./modules/tenant"
     for_each = var.tenants
     name     = each.key
     # pass each.value fields
   }
   ```

4. Use the shared IRSA module (`modules/irsa/`) for pod IAM roles.

Existing multi-tenant components to reference: `druid`, `pipeline`, `gateway`, `llm`, `mlops`, `rag`, `governance`.

## Adding a Tenant

Edit the environment's `terragrunt.hcl` for the component and add an entry to the `tenants` map:

```hcl
# live/staging/druid/terragrunt.hcl
inputs = {
  tenants = {
    existing-tenant = { ... }
    new-tenant = {
      rds_min_acu = 0.5
      rds_max_acu = 8
      msk_enabled = true
    }
  }
}
```

Each component's `variables.tf` documents the full tenant schema with defaults.

## Adding a New Environment

1. Copy an existing environment directory: `cp -r live/dev/ live/<env>/`
2. Update `live/<env>/env.hcl` with the new account ID, region, and environment name
3. Adjust component inputs (node counts, feature toggles, etc.)
4. Add the environment to `deploy.yml` and optionally `destroy.yml` dispatch inputs
5. Create the S3 backend bucket: `./scripts/init-backend.sh <account_id> <region>`

## Code Style

- **OpenTofu, not Terraform** — use `tofu` CLI, never `terraform`
- **Formatting** — `tofu fmt` style (2-space indent, aligned `=`)
- **Documentation** — all variables and outputs must have `description`
- **Naming** — snake_case everywhere
- **Tags** — never duplicate default tags in components
- **Dependencies** — wiring goes in `live/_envcommon/`, not in the component
- **State** — one state file per component per environment, S3 backend with native locking
