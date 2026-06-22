#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${INFRA_ROOT}/terraform"
WORKSHOP_SRC="${INFRA_ROOT}/workshop"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "${TMP_ROOT}"' EXIT

cd "${TERRAFORM_DIR}"

GIT_PAT="$(terraform output -raw azuredevops_git_pat)"
REPOS_JSON="$(terraform output -json participant_repositories)"
AUTH_HEADER="$(printf ':%s' "${GIT_PAT}" | base64 | tr -d '\r\n')"

python3 - "$REPOS_JSON" <<'PY' > "${TMP_ROOT}/repos.tsv"
import json
import sys

repos = json.loads(sys.argv[1])
for owner, info in sorted(repos.items()):
    print(f"{owner}\t{info['remote_url']}")
PY

while IFS=$'\t' read -r owner repo_url; do
  echo "Bootstrapping ${owner}: ${repo_url}"

  workdir="${TMP_ROOT}/${owner}"
  mkdir -p "${workdir}"

  (
    cd "${WORKSHOP_SRC}"
    tar -cf - .
  ) | (
    cd "${workdir}"
    tar -xf -
  )

  git -C "${workdir}" init
  git -C "${workdir}" config user.name "iac-workshop-organizer"
  git -C "${workdir}" config user.email "iac-workshop-organizer@example.local"
  git -C "${workdir}" add .
  git -C "${workdir}" commit -m "Initial workshop template"
  git -C "${workdir}" branch -M main
  git -C "${workdir}" remote add origin "${repo_url}"
  git -C "${workdir}" -c "http.extraHeader=AUTHORIZATION: Basic ${AUTH_HEADER}" push -f origin main
done < "${TMP_ROOT}/repos.tsv"

echo "Repository bootstrap complete."
