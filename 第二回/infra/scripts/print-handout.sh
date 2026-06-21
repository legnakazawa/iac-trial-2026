#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${SCRIPT_DIR}/../credentials/participants.csv"

if [[ ! -f "${CSV}" ]]; then
  echo "Error: ${CSV} not found. Run scripts/gen-compose.py first." >&2
  exit 1
fi

echo "# ワークショップ接続情報"
echo ""
echo "ブラウザで以下の URL を開き、パスワードを入力してください。"
echo ""

tail -n +2 "${CSV}" | while IFS=, read -r seat url password owner; do
  echo "## 席 ${seat} (${owner})"
  echo "- URL: ${url}"
  echo "- パスワード: ${password}"
  echo ""
done
