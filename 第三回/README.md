# 第三回 IaC ワークショップ

第三回は、code-server 上で Terraform ファイルを変更し、Azure Repos の参加者専用リポジトリへ push します。`feature` ブランチを `main` に merge して push すると Azure Pipelines が起動し、Terraform が自動で `apply` されることを確認します。

詳細は [infra/README.md](./infra/README.md) を参照してください。
