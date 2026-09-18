# AWS Dev Environment Decisions (EPIC-2)

Decision record for the AWS foundation of the TodoList project. Decisions are recorded **before**
any billable resource is provisioned and are referenced by the infrastructure runbook.

- **Status:** Accepted (pending the open items in the last section)
- **Scope:** one `dev` EKS environment. Production is optional and out of scope until R0–R5 pass.

## ADR-001 — Infrastructure repository placement and ownership

**Context.** The project uses a dedicated infrastructure repository and an application repository.
The delivery plan requires a clear boundary between infrastructure lifecycle and application
releases.

**Decision.**

- The infrastructure repository owns the AWS foundation, managed with OpenTofu.
- The application repository keeps the image, Helm chart, and CI workflow.
- OpenTofu owns the cluster and all cluster add-ons. GitHub Actions owns only the application Helm
  release. Neither owns the other's resources.
- Add-on bootstrap is applied by the infrastructure repository (OpenTofu and/or bootstrap Helm). The
  application repository must not install cluster-wide controllers.

**Consequences.** Two repositories to maintain and a documented bootstrap order (cluster → add-ons →
app). Prevents state ownership conflicts and accidental app-pipeline destruction of infrastructure.

## ADR-002 — AWS account and region

**Decision.**

- Use the existing AWS account and region **`us-east-1`**.
- Use short-lived credentials and OIDC where possible; no long-lived access keys in the repository.
- Account identifiers and account-specific details are never committed.

**Consequences.** A single region to reason about. If latency matters more than cost, revisit
`sa-east-1` knowing its hourly rates are higher.

## ADR-003 — Environment scope, sizing, and budget

**Context.** The required cloud deliverable is one dev environment, not production. It is a
short-lived proof of concept that is destroyed after use. Budget target: **US$50/month**.

**Decision.**

- Provision exactly one `dev` EKS environment.
- Worker node type: **`t3.small`** (2 vCPU, 2 GiB), **one node minimum, two maximum** for rollout
  and scaling headroom via Cluster Autoscaler.
- Keep cluster add-ons lean to fit 2 GiB: one CoreDNS replica and one EBS CSI controller replica;
  add Cluster Autoscaler, metrics-server, AWS Load Balancer Controller, and External Secrets
  Operator as the epics require them.
- Fallback: switch to **`t3.medium`** (2 vCPU, 4 GiB) if pods go `Pending` or are OOM-killed.
  `t4g.small` (ARM, slightly cheaper) is an option only if the image is built for `arm64`.
- Treat dev as ephemeral: create for validation/demo windows and destroy afterward.
- Configure AWS Budget alerts (50/80/100% of US$50). Alerts are not spending caps.
- A single NAT gateway and a single Aurora writer are explicit dev compromises.

**Rationale.** `t3.micro` (1 GiB) is too small. `t3.small` is the smallest practical x86 node: on a
2 GiB node roughly 1.4 GiB is allocatable after kubelet reservations, and the add-on set consumes
most of it, leaving little headroom for the application. Node size is a small share of total cost —
EKS, NAT, ALB, and Aurora dominate — so `t3.medium` is a low-cost fallback (about US$0.03 more per
hour) when demo stability matters more than the absolute minimum.

**Consequences.** See [`costs.md`](costs.md). US$50/month requires short-lived windows; an
always-on stack is roughly 4× the budget. No production promotion stage is required.

## ADR-004 — EKS and add-on version selection

**Context.** The plan forbids hard-coding an outdated version as "latest"; versions are chosen at
implementation time and remain in standard support.

**Decision.**

- EKS Kubernetes **1.36**, the latest version in standard support in `us-east-1` at decision time.
  Re-check before apply and pin it in a variable rather than assuming.
- Managed add-ons, recommended/default builds for 1.36 at decision time:
  - `vpc-cni` `v1.22.4-eksbuild.3`
  - `coredns` `v1.14.3-eksbuild.23`
  - `kube-proxy` `v1.36.0-eksbuild.25`
  - `aws-ebs-csi-driver` `v1.66.0-eksbuild.1`
- Helm add-ons (AWS Load Balancer Controller, External Secrets Operator, metrics-server, Cluster
  Autoscaler): pin chart versions in variables and record them here when applied.
- Pin the OpenTofu providers (`hashicorp/aws`, `hashicorp/kubernetes`, `hashicorp/helm`) and commit
  `.terraform.lock.hcl`.

**Consequences.** Version choices are reproducible and reviewable. Versions are re-verified at
apply time.

## ADR-005 — Aurora PostgreSQL Serverless v2 settings

**Context.** The application uses PostgreSQL. Dev must be managed and cheap, but Aurora Serverless
v2 is **not** free when idle.

**Decision.**

- Engine: **Aurora PostgreSQL Serverless v2**, latest supported engine version at implementation.
- Capacity: minimum **0.5 ACU**, maximum **2 ACU** for dev; a single writer, no reader.
- Private connectivity only; a database subnet group across the AZs Aurora requires.
- Backups: 7-day retention; decide per teardown whether a snapshot is required.
- `deletion_protection` disabled for dev, with a documented snapshot step before destroy.

**Consequences.** Minimum ACU and storage charges accrue while the cluster exists; auto-pause
support depends on engine/version and must be verified, not assumed. Aurora storage is distributed
across AZs, but a single compute instance is **not** equivalent to redundant compute/failover.

## ADR-006 — CI access to the EKS API

**Context.** GitHub-hosted runners have dynamic public IPs. Exposing the EKS API endpoint to the
internet, even authenticated, is rejected as a shortcut.

**Decision.**

- Run CI on a **self-hosted GitHub Actions runner inside the VPC**.
- Preferred implementation: `actions-runner-controller` (ARC) on the cluster, scaled to zero when
  idle. Fallback: a single small runner EC2 instance in a private subnet if ARC is too
  time-consuming.
- Keep the EKS API endpoint **private** (`endpoint_public_access = false`). If temporary public
  access is needed for operator use, restrict it to explicit CIDRs and never leave it open.
- Runner AWS access uses OIDC/IRSA with least privilege (ECR push, scoped EKS/Helm deploy). Runner
  Kubernetes RBAC is scoped to the application namespace.
- CI reaches EKS in-VPC; outbound to GitHub and AWS uses the dev NAT gateway.

**Consequences.** No public control-plane exposure; an extra bootstrap step to register the runner.
If the runner is unavailable, deploys pause — acceptable for dev.

## ADR-007 — Browser access, DNS, and TLS

**Context.** R3 requires validating the actual documented hostname through the load balancer. A
custom domain is managed in **Route53** and TLS is issued with **ACM**.

**Decision.**

- Expose the app through an **ALB** created by the AWS Load Balancer Controller from a Helm-owned
  `Ingress` with a ClusterIP backend, not a literal `Service type: LoadBalancer`.
- Dev hostname: **`dev.todolist.<base_domain>`**.
- Certificate: an **ACM** certificate for that hostname, DNS-validated through the existing Route53
  hosted zone. An `A`/alias record points the hostname at the ALB.
- The base domain is a **required variable** (`base_domain`, no default) supplied at apply time via
  `terraform.tfvars` or CI secrets, and is never committed.

**Consequences.** HTTPS on the documented hostname, satisfying R3 more strongly than a bare ALB DNS
name. Adds Route53/ACM work and a required variable that must be set before apply.

## ADR-008 — Remote state, bootstrap, and pipeline model

**Context.** CI runners are ephemeral, so OpenTofu state cannot live on a runner. State must be
shared, locked, and protected, and the application pipeline must never manage infrastructure.

**Decision.**

- All state is remote. The `bootstrap` root creates the S3 bucket and then stores its own state in
  it (`key = bootstrap/terraform.tfstate`); the dev root uses `key = dev/terraform.tfstate`. This
  makes the first bootstrap a two-phase step: apply with local state, then `init -migrate-state`.
- The state bucket has versioning, SSE-S3 encryption, a public-access block, an HTTPS-only bucket
  policy, noncurrent-version expiry, and `prevent_destroy = true`.
- State locking uses S3 native lock files (`use_lockfile = true`, OpenTofu 1.10+), so no DynamoDB
  table is required.
- The bucket name is supplied as partial backend configuration and never committed. In CI it is
  derived at runtime from the caller identity; locally it comes from a gitignored `backend.hcl`.
- Pipelines authenticate with OIDC and short-lived credentials. A plan is produced as an artifact and
  applied only after approval. A CI concurrency group and the state lock prevent overlapping runs.
- Each environment uses a separate state key and its own IAM role. The application deploy pipeline
  never runs `tofu apply` or `tofu destroy`.
- Dev teardown destroys only the environment stack; the state bucket and required snapshots persist.

**Consequences.** Every stack is reproducible from remote state, bootstrap is self-hosted after the
first apply, and infrastructure stays isolated from application releases. `prevent_destroy` requires
a deliberate code change for an intentional bucket removal.

## Assumptions

- The AWS account, region, and required service quotas are available.
- A Route53 hosted zone for `base_domain` exists and ACM DNS validation can be completed.
- The estimates in [`costs.md`](costs.md) are validated against current AWS pricing before apply.
- The selected EKS and add-on versions remain in standard support at apply time.
