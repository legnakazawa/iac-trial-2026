Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvPath = Join-Path $scriptDir '../credentials/participants.csv'
$csvPath = [System.IO.Path]::GetFullPath($csvPath)

if (-not (Test-Path -LiteralPath $csvPath)) {
    throw "Error: $csvPath not found. Run scripts/gen-compose.py first."
}

Write-Output '# 第三回ワークショップ接続情報'
Write-Output ''
Write-Output 'ブラウザで以下の URL を開き、パスワードを入力してください。'
Write-Output '各席には専用の Azure Repos リポジトリが割り当てられています。'
Write-Output ''

Import-Csv -LiteralPath $csvPath | ForEach-Object {
    Write-Output "## 席 $($_.seat) ($($_.owner))"
    Write-Output "- code-server URL: $($_.url)"
    Write-Output "- パスワード: $($_.password)"
    Write-Output "- Azure Repos: $($_.repo_url)"
    Write-Output ''
}