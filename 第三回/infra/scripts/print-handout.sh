#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/../credentials/participants.csv"

if [[ ! -f "${CSV}" ]]; then
  echo "Error: ${CSV} not found. Run scripts/gen-compose.py first." >&2
  exit 1
fi

echo "# 第三回ワークショップ接続情報"
echo ""
echo "ブラウザで以下の URL を開き、パスワードを入力してください。"
echo "各席には専用の Azure Repos リポジトリが割り当てられています。"
echo ""

tail -n +2 "${CSV}" | while IFS=, read -r seat owner url password repo_url; do
  echo "## 席 ${seat} (${owner})"
  echo "- code-server URL: ${url}"
  echo "- パスワード: ${password}"
  echo "- Azure Repos: ${repo_url}"
  echo ""
done
