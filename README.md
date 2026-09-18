# Infrastructure

OpenTofu-managed AWS foundation for the TodoList DevOps challenge.

- **Scope:** one cost-conscious `dev` environment (EKS + Aurora PostgreSQL + supporting services).
- **Status:** decisions recorded, no infrastructure implemented yet. This repository intentionally
  contains no empty module/environment scaffolding.

## Ownership boundary

Infrastructure lifecycle is deliberately separate from application releases. An application deploy
job must never run `tofu apply` or `tofu destroy`, and infrastructure must never manage the
application's own Kubernetes objects.

| Owner | Manages |
|---|---|
| `infra/` (this repo, OpenTofu + bootstrap Helm) | VPC/subnets/NAT, EKS cluster and node group, IAM/OIDC/IRSA, cluster add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI, AWS Load Balancer Controller, External Secrets Operator, metrics-server, Cluster Autoscaler), Aurora, Secrets Manager, ECR, Route53 records, ACM certificate, self-hosted CI runner |
| `todolist-app/` (app repo) | Application image, Helm chart, GitHub Actions workflow, Kubernetes resources for the app (Deployment, Service, Ingress, HPA, PDB, ExternalSecret) |
| GitHub Actions | Builds the image, publishes to ECR, and runs `helm upgrade` for the application release only |

Cluster add-on bootstrap (including the Load Balancer Controller and External Secrets Operator) is
owned by this repository. The application repository only owns the app's `Ingress` and
`ExternalSecret`, which reference those controllers.

## Planned layout

```text
infra/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── secrets/
│   └── iam/
├── environments/
│   └── dev/
└── docs/
    ├── decisions.md   # ADR-style record for EPIC-2
    └── costs.md       # Cost drivers, estimates, and budget model
```

Modules and the `dev` environment root are added during implementation (EPIC-2/3/4/5). Prod and
staging roots are added only if those environments are approved.

## Safety

- State is stored in a protected, encrypted remote backend with locking, bootstrapped separately
  from the disposable dev stack, and retained across teardown/recreation. State is never committed.
- The dev environment is created for validation/demo windows and destroyed afterward. Scaling nodes
  to zero does not stop EKS control-plane, storage, or other charges.
- Never disable production deletion safeguards to reuse the dev teardown procedure.

See [`docs/decisions.md`](docs/decisions.md) and [`docs/costs.md`](docs/costs.md).
