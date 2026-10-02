#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly AWS_PROFILE_NAME="multicloud-lab"
readonly AWS_REGION="eu-west-2"
readonly GCP_PROJECT="multicloud-lab-prp"
readonly GCP_NETWORK="multicloud-lab-vpc"

"$REPO_ROOT/scripts/preflight.sh"

aws_vpc_id="$(terraform -chdir="$REPO_ROOT/infra" output -raw aws_vpc_id)"
aws_subnet_id="$(terraform -chdir="$REPO_ROOT/infra" output -raw aws_subnet_id)"
aws_route_table_id="$(terraform -chdir="$REPO_ROOT/infra" output -raw aws_route_table_id)"

aws_subnet="$(aws ec2 describe-subnets \
  --profile "$AWS_PROFILE_NAME" \
  --region "$AWS_REGION" \
  --subnet-ids "$aws_subnet_id" \
  --output json)"

jq -e --arg vpc "$aws_vpc_id" '
  .Subnets | length == 1 and
  .[0].VpcId == $vpc and
  .[0].CidrBlock == "10.10.0.0/24" and
  .[0].MapPublicIpOnLaunch == false
' <<<"$aws_subnet" >/dev/null

aws_routes="$(aws ec2 describe-route-tables \
  --profile "$AWS_PROFILE_NAME" \
  --region "$AWS_REGION" \
  --route-table-ids "$aws_route_table_id" \
  --output json)"

jq -e --arg vpc "$aws_vpc_id" --arg subnet "$aws_subnet_id" '
  (.RouteTables | length) == 1 and
  .RouteTables[0].VpcId == $vpc and
  (.RouteTables[0].Routes | length) == 1 and
  .RouteTables[0].Routes[0].DestinationCidrBlock == "10.10.0.0/16" and
  .RouteTables[0].Routes[0].GatewayId == "local" and
  .RouteTables[0].Routes[0].State == "active"
' <<<"$aws_routes" >/dev/null

jq -e --arg subnet "$aws_subnet_id" '
  .RouteTables[0].Associations | any(
    .SubnetId == $subnet and .AssociationState.State == "associated"
  )
' <<<"$aws_routes" >/dev/null

gcp_routes="$(gcloud compute routes list \
  --project="$GCP_PROJECT" \
  --filter="network:$GCP_NETWORK" \
  --format=json)"

jq -e --arg network "/global/networks/$GCP_NETWORK" '
  (length == 1) and
  .[0].destRange == "10.30.0.0/24" and
  (.[0].network | endswith($network)) and
  (.[0].nextHopNetwork | endswith($network))
' <<<"$gcp_routes" >/dev/null

echo "AWS subnet and local route verified."
echo "GCP subnet route verified; no default Internet route is present."
