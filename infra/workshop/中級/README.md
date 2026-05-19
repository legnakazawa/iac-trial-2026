# 中級

## ゴール

初級の Storage に加え、以下を **自分で調べて** `main.tf` に追記する。

1. `azurerm_private_endpoint`（Storage Blob 用）
2. `azurerm_application_insights`

`outputs.tf` にも、追記したリソース向けの output を自分で定義する。

## 手順

1. 初級と同様 `terraform init`
2. `main.tf` の TODO 1, 2 に、調べた内容でリソース定義を記述
3. `outputs.tf` に必要な output を追記（[`../完成形/outputs.tf`](../完成形/outputs.tf) を参考）
4. `terraform plan` で差分を確認
5. `terraform apply`

## 参照

完成形: [`../完成形/main.tf`](../完成形/main.tf)

## 次のステップ

上級フォルダで App Service と VNet 統合を一から作成します。
