---
name: validate
description: Run the full validation suite (fmt-check, validate, lint)
user-invocable: true
allowed-tools: Bash(make *)
---

Run the full validation suite in order:

1. `make fmt-check` — verify formatting
2. `make validate` — init + validate all components
3. `make lint` — tflint with AWS plugin

Report results for each step. If any step fails, show the error and suggest a fix.
If formatting fails, offer to run `make fmt` to auto-fix.
