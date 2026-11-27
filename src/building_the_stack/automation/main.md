#  Automation

**Goal:** every system describable as text, every change reviewable.

## Declarative configuration
- NixOS as infrastructure substrate
- Terraform / OpenTofu for cloud/virtualisation resources
- Ansible for imperative gap-filling (where unavoidable)
- Comparison and boundary-drawing

## GitOps
- Signed commits and tag enforcement
- Branch protection and required reviewers
- Flux / Argo CD for Kubernetes
- Pull-based vs. push-based deployment

## Pipeline security
- Runner isolation (ephemeral, least-privilege)
- OIDC federation to cloud and secret stores (no long-lived credentials in CI)
- Artifact signing in-pipeline
- Hermetic builds

## Policy as code
- Open Policy Agent (Rego) fundamentals
- Kyverno for Kubernetes policy
- Conftest for IaC linting

## Immutable infrastructure patterns
- Golden image construction
- Blue/green and canary deployments
- Rollback architecture
