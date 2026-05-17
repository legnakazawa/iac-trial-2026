#!/bin/sh
set -e

WORKSHOP_DIR="/home/coder/workshop"

if [ -d "${WORKSHOP_DIR}" ]; then
  terraform -chdir="${WORKSHOP_DIR}" init -input=false 2>/dev/null || true
fi

exec /usr/bin/code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth password \
  "${WORKSHOP_DIR}"
