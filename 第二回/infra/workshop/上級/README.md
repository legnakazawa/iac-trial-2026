# 上級

## ゴール

`main.tf` をほぼ一から書き、[`../完成形/main.tf`](../完成形/main.tf) と同等の構成をデプロイする。

## 前提

- 中級の内容（Network / Storage / Private Endpoint / App Insights）を理解していること
- 完成形は [`../完成形/main.tf`](../完成形/main.tf) と [`../完成形/outputs.tf`](../完成形/outputs.tf) を参照

## 手順

1. `variables.tf` の `display_name` を設定
2. `main.tf` のコメント一覧に沿ってリソースを追加
3. `outputs.tf` に必要な output を定義（[`../完成形/outputs.tf`](../完成形/outputs.tf) を参考）
4. `terraform init` → `plan` → `apply`

## チェックリスト

- [ ] `local.prefix` に `var.owner` が含まれている
- [ ] Storage Account 名が Azure 全体で一意（`st` + owner + suffix）
- [ ] `public_network_access_enabled = false` かつ Private Endpoint あり
- [ ] App Service の `app_settings` に Insights / Storage の値を設定
- [ ] `azurerm_app_service_virtual_network_swift_connection` でサブネット統合
