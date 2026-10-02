#!/usr/bin/env bash
set -euo pipefail

readonly AWS_PROFILE_NAME="multicloud-lab"
readonly EXPECTED_AWS_ACCOUNT="579939411020"
readonly GCLOUD_CONFIGURATION="multicloud-lab"
readonly EXPECTED_GCP_ACCOUNT="pablo.reypedrosa@gmail.com"
readonly EXPECTED_GCP_PROJECT="multicloud-lab-prp"
readonly EXPECTED_GCP_REGION="europe-west2"
readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${AWS_ACCESS_KEY_ID:-}" || -n "${AWS_SECRET_ACCESS_KEY:-}" || -n "${AWS_SESSION_TOKEN:-}" ]]; then
  echo "ERROR: AWS credential environment variables could override the lab profile." >&2
  exit 1
fi

if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" || -n "${GOOGLE_CREDENTIALS:-}" || -n "${GOOGLE_OAUTH_ACCESS_TOKEN:-}" ]]; then
  echo "ERROR: Google credential environment variables could override the lab ADC credentials." >&2
  exit 1
fi

for state_file in "$REPO_ROOT/infra/terraform.tfstate" "$REPO_ROOT/infra/terraform.tfstate.backup"; do
  if [[ -f "$state_file" && "$(stat -c '%a' "$state_file")" != "600" ]]; then
    echo "ERROR: $state_file must have permissions 600." >&2
    exit 1
  fi
done

aws_account="$(aws sts get-caller-identity \
  --profile "$AWS_PROFILE_NAME" \
  --query Account \
  --output text)"

if [[ "$aws_account" != "$EXPECTED_AWS_ACCOUNT" ]]; then
  echo "ERROR: expected AWS account $EXPECTED_AWS_ACCOUNT, got $aws_account." >&2
  exit 1
fi

gcp_project="$(gcloud config get-value project \
  --configuration="$GCLOUD_CONFIGURATION" 2>/dev/null)"
gcp_account="$(gcloud config get-value account \
  --configuration="$GCLOUD_CONFIGURATION" 2>/dev/null)"
gcp_region="$(gcloud config get-value compute/region \
  --configuration="$GCLOUD_CONFIGURATION" 2>/dev/null)"

if [[ "$gcp_project" != "$EXPECTED_GCP_PROJECT" ]]; then
  echo "ERROR: expected GCP project $EXPECTED_GCP_PROJECT, got $gcp_project." >&2
  exit 1
fi

if [[ "$gcp_account" != "$EXPECTED_GCP_ACCOUNT" ]]; then
  echo "ERROR: expected gcloud account $EXPECTED_GCP_ACCOUNT, got $gcp_account." >&2
  exit 1
fi

if [[ "$gcp_region" != "$EXPECTED_GCP_REGION" ]]; then
  echo "ERROR: expected GCP region $EXPECTED_GCP_REGION, got $gcp_region." >&2
  exit 1
fi

adc_file="$(gcloud info --format='value(config.paths.global_config_dir)')/application_default_credentials.json"
adc_quota_project="$(jq -r '.quota_project_id // empty' "$adc_file")"

if [[ "$adc_quota_project" != "$EXPECTED_GCP_PROJECT" ]]; then
  echo "ERROR: expected ADC quota project $EXPECTED_GCP_PROJECT, got $adc_quota_project." >&2
  exit 1
fi

adc_token="$(gcloud auth application-default print-access-token)"
adc_account="$(curl --fail --silent --show-error \
  --header "Authorization: Bearer $adc_token" \
  https://openidconnect.googleapis.com/v1/userinfo | jq -r '.email // empty')"
unset adc_token

if [[ "$adc_account" != "$EXPECTED_GCP_ACCOUNT" ]]; then
  echo "ERROR: expected ADC account $EXPECTED_GCP_ACCOUNT, got $adc_account." >&2
  exit 1
fi

echo "AWS account verified: $aws_account"
echo "GCP configuration verified: $gcp_account, $gcp_project, $gcp_region"
echo "ADC verified: $adc_account, quota project $adc_quota_project"
