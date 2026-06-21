# 第三回 ワークショップリポジトリ

このリポジトリは、Azure Repos への `main` ブランチ push を契機に Azure Pipelines が Terraform を実行する教材です。

## 実施すること

1. `feature/workshop-change` ブランチを作成
2. `main.tf` の TODO を編集
3. feature ブランチへ commit / push
4. feature ブランチを `main` に merge
5. `main` を push して Pipeline による `terraform apply` を確認

## 編集箇所

`main.tf` の `azurerm_linux_web_app.main` にある `app_settings` の TODO コメントを探してください。

```hcl
# "WORKSHOP_CHANGE" = var.display_name
```

この行のコメントを外し、`variables.tf` の `display_name` を自分の名前に変更してから commit します。

## 注意

- `terraform apply` はローカルで実行しません。Pipeline が実行します。
- `terraform init` は remote state を使うため、ローカルで実行すると追加設定が必要です。
- `main` に push した時点で Azure 上のリソースが変更されます。
