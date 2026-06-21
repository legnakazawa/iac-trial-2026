#!/bin/sh
set -eu

if [ -z "${GIT_REPO_URL:-}" ] || [ -z "${GIT_PAT:-}" ]; then
  echo "GIT_REPO_URL and GIT_PAT are required." >&2
  exit 1
fi

git config --global user.name "${GIT_USER_NAME:-iac-workshop}"
git config --global user.email "${GIT_USER_EMAIL:-iac-workshop@example.local}"
git config --global init.defaultBranch main
git config --global credential.helper store

# Azure DevOps PATs are normally alphanumeric. Keep the remote usable for push
# while avoiding any need for participant-side az login.
AUTH_REPO_URL="$(printf "%s" "${GIT_REPO_URL}" | sed "s#^https://#https://user:${GIT_PAT}@#")"
printf "%s\n" "${AUTH_REPO_URL}" > "${HOME}/.git-credentials"

if [ -d "/home/coder/workshop/.git" ]; then
  git -C /home/coder/workshop remote set-url origin "${AUTH_REPO_URL}"
fi
