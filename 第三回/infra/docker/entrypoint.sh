#!/bin/sh
set -eu

WORKSHOP_DIR="/home/coder/workshop"

/usr/local/bin/setup-git-credentials.sh

AUTH_REPO_URL="$(printf "%s" "${GIT_REPO_URL}" | sed "s#^https://#https://user:${GIT_PAT}@#")"

if [ ! -d "${WORKSHOP_DIR}/.git" ]; then
  rm -rf "${WORKSHOP_DIR:?}"/*
  git clone "${AUTH_REPO_URL}" "${WORKSHOP_DIR}"
fi

git -C "${WORKSHOP_DIR}" fetch origin main || true
git -C "${WORKSHOP_DIR}" checkout main || true
git -C "${WORKSHOP_DIR}" pull --ff-only origin main || true
git -C "${WORKSHOP_DIR}" remote set-url origin "${AUTH_REPO_URL}"

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
