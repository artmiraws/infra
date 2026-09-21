#!/usr/bin/env bash
#
# Cost control for the ephemeral environments.
#
#   scripts/cost.sh status            # what is running and the estimated hourly burn
#   scripts/cost.sh sleep [env ...]   # stop Aurora and scale nodes to 0 (keeps EKS + NAT)
#   scripts/cost.sh wake  [env ...]   # start Aurora and scale nodes back up
#
# EKS control planes and NAT gateways cannot be paused; only `tofu destroy` stops them. Sleep is for
# short breaks (overnight); for longer gaps, destroy and recreate. See the platform handbook runbook.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
PROJECT="${PROJECT:-todolist}"
ACTION="${1:-status}"
shift || true
ENVS=("$@")
if [ "${#ENVS[@]}" -eq 0 ]; then ENVS=(dev prod); fi

# Indicative us-east-1 on-demand rates (USD/hour). Keep in sync with the handbook cost model.
R_EKS=0.10
R_NAT=0.045
R_ACU=0.12
R_NODE=0.0232
R_ALB=0.0225
R_IPV4=0.005

cluster_name() { echo "${PROJECT}-$1"; }

nodegroup_name() {
  aws eks list-nodegroups --cluster-name "$1" --query 'nodegroups[0]' --output text 2>/dev/null || true
}

nodegroup_scaling() {
  aws eks describe-nodegroup --cluster-name "$1" --nodegroup-name "$2" \
    --query 'nodegroup.scalingConfig' --output json 2>/dev/null || echo '{}'
}

aurora_status() {
  aws rds describe-db-clusters --db-cluster-identifier "$1" \
    --query 'DBClusters[0].Status' --output text 2>/dev/null || echo "absent"
}

cmd_status() {
  local eks=0 nat=0 aurora=0 nodes=0
  printf '%-6s %-8s %-16s %-12s %s\n' ENV EKS NODES AURORA NAT
  for env in "${ENVS[@]}"; do
    local c ng sc des aur natc
    c="$(cluster_name "$env")"
    if ! aws eks describe-cluster --name "$c" >/dev/null 2>&1; then
      printf '%-6s %-8s %-16s %-12s %s\n' "$env" "absent" "-" "-" "-"
      continue
    fi
    ng="$(nodegroup_name "$c")"
    sc="$(nodegroup_scaling "$c" "$ng")"
    des="$(echo "$sc" | grep -o '"desiredSize": *[0-9]*' | grep -o '[0-9]*' || echo 0)"
    aur="$(aurora_status "$c")"
    natc="$(aws ec2 describe-nat-gateways --filter "Name=state,Values=available" "Name=tag:Name,Values=${c}-nat" --query 'length(NatGateways)' --output text 2>/dev/null || echo 0)"
    printf '%-6s %-8s %-16s %-12s %s\n' "$env" "up" "desired=${des}" "$aur" "$natc"
    eks=$((eks + 1))
    nodes=$((nodes + des))
    nat=$((nat + natc))
    [ "$aur" = "available" ] && aurora=$((aurora + 1))
  done

  local albs ipv4 total
  albs="$(aws elbv2 describe-load-balancers --query 'length(LoadBalancers)' --output text 2>/dev/null || echo 0)"
  ipv4=$((nat + albs))
  total="$(awk -v e="$eks" -v n="$nat" -v a="$aurora" -v nd="$nodes" -v l="$albs" -v ip="$ipv4" \
    -v re="$R_EKS" -v rn="$R_NAT" -v ra="$R_ACU" -v rnode="$R_NODE" -v rl="$R_ALB" -v rip="$R_IPV4" \
    'BEGIN{printf "%.4f", e*re + n*rn + a*0.5*ra + nd*rnode + l*rl + ip*rip}')"

  echo
  echo "Resources: EKS=${eks}  NAT=${nat}  Aurora(available)=${aurora}  nodes=${nodes}  ALBs=${albs}"
  echo "Estimated burn: \$${total}/hour  (~\$$(awk -v t="$total" 'BEGIN{printf "%.0f", t*24}')/day, ~\$$(awk -v t="$total" 'BEGIN{printf "%.0f", t*730}')/month)"
  echo "Sleep removes the node + Aurora lines; EKS and NAT (the floor) only stop on destroy."
}

cmd_sleep() {
  for env in "${ENVS[@]}"; do
    local c ng
    c="$(cluster_name "$env")"
    ng="$(nodegroup_name "$c")"
    if [ "$(aurora_status "$c")" = "available" ]; then
      echo "[$env] stopping Aurora cluster $c ..."
      aws rds stop-db-cluster --db-cluster-identifier "$c" >/dev/null
    else
      echo "[$env] Aurora $c is $(aurora_status "$c"); not stopping."
    fi
    if [ -n "$ng" ]; then
      echo "[$env] scaling node group $ng to 0 ..."
      aws eks update-nodegroup-config --cluster-name "$c" --nodegroup-name "$ng" \
        --scaling-config minSize=0,desiredSize=0 >/dev/null
    fi
  done
  echo "Sleeping. Wake with: scripts/cost.sh wake ${ENVS[*]}"
}

cmd_wake() {
  local desired="${WAKE_DESIRED:-2}"
  for env in "${ENVS[@]}"; do
    local c ng
    c="$(cluster_name "$env")"
    ng="$(nodegroup_name "$c")"
    if [ "$(aurora_status "$c")" = "stopped" ]; then
      echo "[$env] starting Aurora cluster $c ..."
      aws rds start-db-cluster --db-cluster-identifier "$c" >/dev/null
    else
      echo "[$env] Aurora $c is $(aurora_status "$c"); not starting."
    fi
    if [ -n "$ng" ]; then
      echo "[$env] scaling node group $ng to min 1 / desired $desired ..."
      aws eks update-nodegroup-config --cluster-name "$c" --nodegroup-name "$ng" \
        --scaling-config minSize=1,desiredSize="$desired" >/dev/null
    fi
  done
  echo "Waking. Argo CD reconciles once the nodes are Ready."
}

case "$ACTION" in
  status) cmd_status ;;
  sleep)  cmd_sleep ;;
  wake)   cmd_wake ;;
  *) echo "usage: $0 {status|sleep|wake} [env ...]" >&2; exit 2 ;;
esac
