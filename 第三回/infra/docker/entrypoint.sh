#!/bin/sh
set -eu

WORKSHOP_DIR="/home/coder/workshop"
REPO_URL="$(printf "%s" "${GIT_REPO_URL}" | sed 's#^https://[^/@]*@#https://#')"
GIT_SYNC_ERROR=""

/usr/local/bin/setup-git-credentials.sh

if [ ! -d "${WORKSHOP_DIR}/.git" ]; then
  rm -rf "${WORKSHOP_DIR:?}"/*
  if ! git clone "${REPO_URL}" "${WORKSHOP_DIR}"; then
    GIT_SYNC_ERROR="Initial clone failed for ${REPO_URL}. Check azuredevops_git_pat permissions and repository access."
  fi
fi

if [ -d "${WORKSHOP_DIR}/.git" ]; then
  git -C "${WORKSHOP_DIR}" fetch origin main || true
  git -C "${WORKSHOP_DIR}" checkout main || true
  git -C "${WORKSHOP_DIR}" pull --ff-only origin main || true
  git -C "${WORKSHOP_DIR}" remote set-url origin "${REPO_URL}"
fi

if [ -n "${GIT_SYNC_ERROR}" ]; then
  cat > "${WORKSHOP_DIR}/WORKSHOP-GIT-ERROR.txt" <<EOF
${GIT_SYNC_ERROR}

Configured repository:
${REPO_URL}
EOF
fi

# Inject the Terraform remote-state backend connection info at workspace init.
# Auth is the VM managed identity (MSI) via IMDS, so no secret is written here.
if [ -n "${TF_STATE_STORAGE_ACCOUNT_NAME:-}" ]; then
  cat > "${WORKSHOP_DIR}/backend.hcl" <<EOF
resource_group_name  = "${TF_STATE_RESOURCE_GROUP_NAME}"
storage_account_name = "${TF_STATE_STORAGE_ACCOUNT_NAME}"
container_name       = "${TF_STATE_CONTAINER_NAME}"
key                  = "${TF_STATE_KEY:-terraform.tfstate}"
use_azuread_auth     = true
use_msi              = true
client_id            = "${ARM_CLIENT_ID}"
EOF
fi

cat > "${WORKSHOP_DIR}/WORKSHOP-TERRAFORM-FLOW.txt" <<'EOF'
Third workshop Terraform flow (run everything in this code-server terminal):

Auth: the VM managed identity is used automatically (ARM_USE_MSI=true).
Backend settings are injected into backend.hcl at startup.

1. terraform init -backend-config=backend.hcl
2. terraform plan      # TF_VAR_owner / TF_VAR_resource_group_name are pre-set
3. terraform apply

Edit main.tf / variables.tf, then re-run plan & apply.
Use git only to version your changes (no pipeline is required):
  git checkout -b feature/workshop-change
  git add . && git commit -m "Update workshop setting"
  git push -u origin feature/workshop-change
EOF

exec /usr/bin/code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth password \
  "${WORKSHOP_DIR}"
