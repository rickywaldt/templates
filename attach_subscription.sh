#!/usr/bin/env bash
set -euo pipefail

# --- Required environment variables ---
# OCM_TOKEN        - Offline access token from https://console.redhat.com/openshift/token/show
# SUPPORT_LEVEL    - e.g. "Standard" or "Premium" (defaults to Standard)
# USAGE            - e.g. "Development/Test" or "Production" (defaults to Development/Test)
# SERVICE_LEVEL    - e.g. "L1-L3" (defaults to L1-L3)
# SYSTEM_UNITS     - e.g. "Cores/vCPU" (defaults to Cores/vCPU)
#
# Assumes `oc` is already logged into the target cluster (KUBECONFIG set)
# and that `ocm` and `jq` are installed on the runner image.

SUPPORT_LEVEL="${SUPPORT_LEVEL:-Standard}"
USAGE="${USAGE:-Development/Test}"
SERVICE_LEVEL="${SERVICE_LEVEL:-L1-L3}"
SYSTEM_UNITS="${SYSTEM_UNITS:-Cores/vCPU}"

if [[ -z "${OCM_TOKEN:-}" ]]; then
  echo "ERROR: OCM_TOKEN is not set" >&2
  exit 1
fi

echo "Logging into OCM..."
ocm login --token="${OCM_TOKEN}"

echo "Fetching cluster UUID..."
CLUSTER_UUID=$(oc get clusterversion version -o jsonpath='{.spec.clusterID}')
if [[ -z "${CLUSTER_UUID}" ]]; then
  echo "ERROR: could not determine cluster UUID" >&2
  exit 1
fi
echo "Cluster UUID: ${CLUSTER_UUID}"

echo "Looking up OCM subscription ID..."
CID=$(ocm get subs -p search="external_cluster_id='${CLUSTER_UUID}'" | jq -r '.items[0].href')
if [[ -z "${CID}" || "${CID}" == "null" ]]; then
  echo "ERROR: no subscription found for cluster ${CLUSTER_UUID}" >&2
  exit 1
fi
echo "Subscription href: ${CID}"

echo "Patching subscription..."
PATCH_PAYLOAD=$(jq -n \
  --arg support_level "$SUPPORT_LEVEL" \
  --arg usage "$USAGE" \
  --arg service_level "$SERVICE_LEVEL" \
  --arg system_units "$SYSTEM_UNITS" \
  '{support_level:$support_level, usage:$usage, service_level:$service_level, system_units:$system_units}')

echo "${PATCH_PAYLOAD}" | ocm patch "${CID}"

echo "Subscription updated successfully."
ocm logout
