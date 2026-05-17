# ワークショップ基盤（infra）

ブラウザ上の VS Code（code-server）を Azure VM 上で動かし、参加者が Azure / GitHub アカウントなしで Terraform ハンズオンを行うための構成です。

| ドキュメント | 対象 |
|-------------|------|
| [README-organizer.md](./README-organizer.md) | 主催者（構築・配布・片付け） |
| [README-participant.md](./README-participant.md) | 参加者（ブラウザ接続・Terraform 実行） |

## クイックスタート（主催者）

```bash
cd infra/terraform && cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集後
terraform init && terraform apply

cd ..
python3 scripts/gen-compose.py
./scripts/deploy-to-vm.sh
./scripts/print-handout.sh
```
