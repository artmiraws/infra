# Dev runbook

Operational guide for the `dev` environment. Audience: the operator (and AI agents helping them).

## Architecture (summary)

- **AWS `us-east-1`:** one VPC (2 AZs), EKS `todolist-dev` (managed node group, `t3.small`, min 1 /
  max 3), Aurora PostgreSQL Serverless v2 (single writer, 0.5–2 ACU), ECR, Secrets Manager,
  Route 53 + ACM, and a US$50 budget.
- **Cluster add-ons:** External Secrets Operator, AWS Load Balancer Controller, ExternalDNS,
  metrics-server, Cluster Autoscaler, and ARC runners (one for the app, one for infra).
- **Delivery:** GitHub Actions → self-hosted ARC runner (IRSA, in-VPC) → ECR (by digest) → Helm →
  app pods. Access: Route 53 → ALB (ACM TLS) → Ingress → Service → pods → Aurora.
- The app reads credentials from Secrets Manager via ESO; no credentials are committed.

See `decisions.md` for the rationale and `costs.md` for the budget model.

## Prerequisites

- AWS credentials (short-lived; `aws login` + a bridge profile for the SDK).
- OpenTofu ≥ 1.10, `kubectl`, `helm`, `docker`.
- The GitHub App credentials stored in Secrets Manager as `todolist-dev/github-app`.
- The five GitHub **Environment** variables (`APP_HOSTNAME`, `DB_HOST`, `DB_SECRET_ARN`,
  `APP_SECRET_ARN`, `INGRESS_CERT_ARN`).

## Provision

1. **Bootstrap remote state (once).** Apply with local state, then self-host it:
   ```bash
   tofu -chdir=infra/bootstrap init -backend=false
   tofu -chdir=infra/bootstrap apply
   tofu -chdir=infra/bootstrap init -migrate-state -backend-config=backend.hcl
   ```
2. **Foundation + add-ons.**
   ```bash
   tofu -chdir=infra/environments/dev init -backend-config=backend.hcl
   tofu -chdir=infra/environments/dev apply
   ```
   Or run the infra pipeline (plan on PR, apply with approval).

## Deploy the app

- Push to `main`: CI builds, scans (Trivy, fails on CRITICAL), pushes to ECR by digest, deploys with
  Helm, and runs a smoke test. See `todolist-app/docs/ci-cd.md`.
- The app pipeline reads its wiring from GitHub Environment variables (or the SSM parameters under
  `/todolist/dev`).

## Access

```bash
aws eks update-kubeconfig --name todolist-dev --region us-east-1 --alias todolist-dev
kubectl get nodes -o wide
```

- URL: `https://dev.todolist.<base_domain>` (login `admin`; the password is in Secrets Manager
  `todolist-dev/app`).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Error acquiring the state lock` | Stale S3 lock from an interrupted run. `tofu force-unlock <id>` after confirming no run is active. **Never** `-lock=false`. |
| `kubectl`/k9s timeout | The operator IP changed. Update the allowlist out-of-band, then reconcile: `aws eks update-cluster-config --name todolist-dev --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs=<ip>/32`, `aws eks wait cluster-active --name todolist-dev`, update `cluster_public_access_cidrs`, `tofu apply`. |
| Helm release stuck in `failed` | Releases use `atomic = true`, so a failed install rolls back. If one lingers, `helm uninstall <release> -n <ns>` and re-apply. |
| Pods `Pending` | Node pod-density limit. Cluster Autoscaler adds a node (min 1 / max 3); check `kubectl -n kube-system logs deploy/cluster-autoscaler-aws-cluster-autoscaler`. |
| App `CrashLoopBackOff` | Database not reachable or the ExternalSecret hasn't synced: `kubectl -n todolist get externalsecret`, `kubectl -n todolist get configmap todolist -o yaml`. |
| ALB webhook `x509` errors | The ALB controller webhook cert rotated. `keepTLSSecret` prevents this on upgrades. |

## Teardown and recreate

1. **Pause app deploys** so CI does not race with teardown.
2. **Remove controller-owned load balancers** (delete the app Ingress and wait for the ALB to be
   removed) while the cluster is still running.
3. **Decide on data:** dev data is disposable (`skip_final_snapshot = true`). To retain it, set
   `db_skip_final_snapshot = false` (or take a snapshot) before destroying.
4. **Destroy:**
   ```bash
   tofu -chdir=infra/environments/dev destroy
   ```
   The state bucket is `prevent_destroy` and is **not** removed.
5. **Recreate:** repeat *Provision*, then push to `main` to deploy the app.
6. **Audit residual billable resources:** retained snapshots, ECR images, logs, public IPs.

## Recovery

- **App rollback:** redeploy the previous known-good image digest (Helm `--set image.digest=<prev>`).
- **Database:** 7-day backups with point-in-time restore; restore into a new cluster. Image rollback
  does not revert the schema.
- **State:** retained and versioned in S3.

## Verification evidence (DEV-VERIFY)

- Login + task operations over HTTPS; `/healthz` → `ok`.
- Pod replacement: deleting a pod is recovered in ~7s with no downtime.
- Rolling updates: `maxUnavailable: 0` + PDB; CI deploys roll pods with the service staying up.
- **HPA** scaled 2 → 6 replicas under load; **Cluster Autoscaler** added a node (2 → 3).
- Aurora: 7-day retention and point-in-time restore.

**HA distinctions (explicit dev compromises):** pod recovery is not node/AZ HA (one node group, one
NAT gateway), and a single Aurora writer is not database HA (no reader/failover).

## Costs

See [`costs.md`](costs.md). Dev is ephemeral — destroy it between demo windows.
