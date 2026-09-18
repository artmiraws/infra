# Infrastructure

OpenTofu-managed AWS foundation for the TodoList DevOps challenge.

- **Scope:** one cost-conscious `dev` environment (EKS + Aurora PostgreSQL + supporting services).
- **Status:** remote state, VPC/networking, EKS, and budget alerts implemented. Database, secrets,
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
│   ├── vpc/              # reusable VPC, subnets, NAT, route tables
│   └── eks/              # EKS cluster, managed node group, IRSA, add-ons
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
block, an HTTPS-only bucket policy, noncurrent-version expiration, and `prevent_destroy`. Its own
state is self-hosted in that bucket (`bootstrap/terraform.tfstate`), so the first bootstrap is
two-phase: apply once with local state, then `tofu init -migrate-state` with the bucket name (see
`bootstrap/backend.hcl.example`).

The dev environment uses the same bucket (`dev/terraform.tfstate`) through partial backend
configuration and native file locking (`use_lockfile = true`, OpenTofu 1.10+), so no DynamoDB table
is required. The bucket name is never committed; it is supplied through a gitignored `backend.hcl`
locally and derived at runtime in CI. State is retained across teardown/recreation.

The pipeline and state model is recorded in [`docs/decisions.md`](docs/decisions.md), ADR-008.

## Networking

- Public subnets (one per AZ) host the NAT gateway and the ALB.
- Private subnets (one per AZ) host the EKS nodes; Aurora uses private connectivity.
- Subnets carry the Kubernetes ELB discovery tags and the cluster `shared` tag used by the AWS Load
  Balancer Controller.
- A **single NAT gateway** is a deliberate dev compromise: it is a failure point and can incur
  cross-AZ data-transfer charges when resources in another AZ route through it. Production would use
  one NAT gateway per AZ.

## Cluster access

The EKS API endpoint is private by default: `cluster_public_access_cidrs` is empty, so only in-VPC
clients can reach it. The CI runner runs inside the VPC and uses the private endpoint. An operator
who needs `kubectl` from outside the VPC sets their own address range (for example
`["203.0.113.10/32"]`), which enables the public endpoint restricted to those CIDRs only; it is never
left open to `0.0.0.0/0`. See ADR-006.

The module installs the managed `vpc-cni`, `coredns`, `kube-proxy`, and `aws-ebs-csi-driver`
add-ons, and creates an IAM OIDC provider so workloads (starting with the EBS CSI controller) can
use IRSA. Worker nodes run in private subnets with a single `t3.small` node by default, scaling to
two.

## Cost controls

- A monthly AWS Budget (`budget_limit_usd`, default US$50) alerts at 50/80/100% actual and 100%
  forecasted spend. Budget alerts are notifications, not spending caps.
- Dev is created for validation/demo windows and destroyed afterward. Scaling nodes to zero does not
  stop EKS control-plane, storage, ALB, NAT, or Aurora charges.

See [`docs/decisions.md`](docs/decisions.md) and [`docs/costs.md`](docs/costs.md).
