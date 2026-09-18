# Infrastructure

OpenTofu-managed AWS foundation for the TodoList DevOps challenge.

- **Scope:** one cost-conscious `dev` environment (EKS + Aurora PostgreSQL + supporting services).
- **Status:** remote state, VPC/networking, and budget alerts implemented. EKS, database, secrets,
  and delivery are added in later epics.

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

## Layout

```text
infra/
├── bootstrap/            # S3 remote-state bucket (separate lifecycle)
├── modules/
│   └── vpc/              # reusable VPC, subnets, NAT, route tables
├── environments/
│   └── dev/              # dev root: backend, provider, VPC wiring, budget
└── docs/
    ├── decisions.md      # ADR-style record for EPIC-2
    └── costs.md          # Cost drivers, estimates, and budget model
```

Additional modules (`eks`, `rds`, `secrets`, `iam`) and their dev resources are added during
implementation. Prod and staging roots are added only if those environments are approved.

## Remote state

The `bootstrap` root creates an S3 bucket with versioning, SSE-S3 encryption, a public access
block, an HTTPS-only bucket policy, and noncurrent-version expiration. It uses local state and is
applied once, separately from the disposable dev stack.

The dev environment uses the S3 backend with native file locking (`use_lockfile = true`, OpenTofu
1.10+), so no DynamoDB table is required. The bucket name is not committed; it is supplied at init
time through a gitignored `backend.hcl` (see `backend.hcl.example`). State is retained across
teardown/recreation and is never committed.

## Networking

- Public subnets (one per AZ) host the NAT gateway and the ALB.
- Private subnets (one per AZ) host the EKS nodes; Aurora uses private connectivity.
- Subnets carry the Kubernetes ELB discovery tags and the cluster `shared` tag used by the AWS Load
  Balancer Controller.
- A **single NAT gateway** is a deliberate dev compromise: it is a failure point and can incur
  cross-AZ data-transfer charges when resources in another AZ route through it. Production would use
  one NAT gateway per AZ.

## Cost controls

- A monthly AWS Budget (`budget_limit_usd`, default US$50) alerts at 50/80/100% actual and 100%
  forecasted spend. Budget alerts are notifications, not spending caps.
- Dev is created for validation/demo windows and destroyed afterward. Scaling nodes to zero does not
  stop EKS control-plane, storage, ALB, NAT, or Aurora charges.

See [`docs/decisions.md`](docs/decisions.md) and [`docs/costs.md`](docs/costs.md).
