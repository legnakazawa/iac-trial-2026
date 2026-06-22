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

cat > "${WORKSHOP_DIR}/WORKSHOP-GIT-FLOW.txt" <<'EOF'
Third workshop Git flow:

1. git checkout -b feature/workshop-change
2. Edit main.tf and variables.tf
3. git add . && git commit -m "Update workshop setting"
4. git push -u origin feature/workshop-change
5. git checkout main
6. git merge feature/workshop-change
7. git push origin main

The Azure Pipeline runs only when main is pushed.
EOF

exec /usr/bin/code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth password \
  "${WORKSHOP_DIR}"
