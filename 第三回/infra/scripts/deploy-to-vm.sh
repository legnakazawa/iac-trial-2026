#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${INFRA_ROOT}/terraform"
GENERATED_DIR="${INFRA_ROOT}/docker/generated"
DOCKER_DIR="${INFRA_ROOT}/docker"

cd "${TERRAFORM_DIR}"

VM_IP="$(terraform output -raw vm_public_ip)"
VM_USER="$(terraform output -raw vm_admin_username)"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

if [[ ! -f "${GENERATED_DIR}/docker-compose.yml" ]]; then
  echo "Error: ${GENERATED_DIR}/docker-compose.yml not found. Run scripts/gen-compose.py first." >&2
  exit 1
fi

echo "Deploying to ${VM_USER}@${VM_IP} ..."

ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new "${VM_USER}@${VM_IP}" \
  "mkdir -p /opt/workshop/docker /opt/workshop/workspaces && sudo chown -R ${VM_USER}:${VM_USER} /opt/workshop"

scp -i "${SSH_KEY}" \
  "${DOCKER_DIR}/Dockerfile" \
  "${DOCKER_DIR}/entrypoint.sh" \
  "${DOCKER_DIR}/setup-git-credentials.sh" \
  "${GENERATED_DIR}/docker-compose.yml" \
  "${GENERATED_DIR}/.env" \
  "${VM_USER}@${VM_IP}:/opt/workshop/docker/"

if compgen -G "${DOCKER_DIR}/workspaces/*" > /dev/null; then
  scp -i "${SSH_KEY}" -r "${DOCKER_DIR}/workspaces/"* \
    "${VM_USER}@${VM_IP}:/opt/workshop/workspaces/"
fi

ssh -i "${SSH_KEY}" "${VM_USER}@${VM_IP}" \
  "sudo chown -R ${VM_USER}:${VM_USER} /opt/workshop/workspaces"

ssh -i "${SSH_KEY}" "${VM_USER}@${VM_IP}" bash -s <<'REMOTE'
set -euo pipefail
cd /opt/workshop/docker
sudo docker compose build
sudo docker compose up -d
sudo docker compose ps
REMOTE

echo "Deployment complete."
