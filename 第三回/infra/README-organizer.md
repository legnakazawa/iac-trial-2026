# 主催者向け README

第三回は、参加者が code-server 上で Terraform を編集し、Azure Repos の専用リポジトリに push します。`feature` ブランチを `main` に merge して push したタイミングで Azure Pipelines が起動し、Terraform が自動で `apply` されます。

## 前提条件

| 項目 | 内容 |
|------|------|
| Azure | 主催者が Azure サブスクリプションに Contributor 以上でアクセスできること |
| Azure DevOps | Organization を用意済みであること |
| ローカル | Terraform 1.6+、Azure CLI、Python 3.10+、Git、SSH |
| PAT | Azure DevOps リソース作成用 PAT と、code-server から Git push するための PAT |
| 参加者 | Azure / GitHub / Azure DevOps アカウント不要 |

> `azuredevops_git_pat` は、可能であればワークショップ用 bot ユーザーの PAT を使ってください。終了後に必ず失効します。

## 作成されるもの

| 分類 | 内容 |
|------|------|
| Azure | code-server 用 VM、workshop RG、Terraform state 用 Storage、共有 Private DNS |
| Azure AD | Pipeline 用 Service Principal |
| Azure DevOps | Project、参加者数分の Git repo、Pipeline、Variable Group、Service Connection |
| code-server | 参加者数分の Docker コンテナ |

## 1. Azure / Azure DevOps の準備

```bash
az login
az account set --subscription "<サブスクリプション ID>"
```

Azure DevOps PAT は以下の権限を想定します。

| PAT | 用途 | 推奨スコープ |
|-----|------|--------------|
| `azuredevops_pat` | Terraform が Project / Repo / Pipeline を作成 | Project and Team, Code, Build, Service Connections, Variable Groups |
| `azuredevops_git_pat` | code-server から repo clone / push | Code Read & Write |

## 2. Terraform 変数を設定

```bash
cd 第三回/infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

主に編集する値:

```hcl
admin_ssh_public_key = "ssh-rsa AAAA..."

azuredevops_org_url      = "https://dev.azure.com/your-org"
azuredevops_pat          = "..."
azuredevops_git_pat      = "..."
azuredevops_project_name = "iac-handson-session3"
azuredevops_repo_prefix  = "iac-handson"

participant_count = 10
base_port         = 8001
```

この構成では、Terraform state backend 用の Blob container も参加者ごとに分離されます。`participant_count = 10` の場合、`tfstate-user01` から `tfstate-user10` まで 10 個の container が作成され、各 Pipeline は自分に対応する container の `terraform.tfstate` だけを利用します。

すでに単一 container 構成で参加者側の state を作成済みの場合、新しい container へは自動移行されません。切り替え前に既存 blob を対応する container へ移すか、参加者 Pipeline 初回実行前の段階でこの変更を適用してください。

社内ネットワークに合わせて、必要に応じて接続元 CIDR を絞ります。

```hcl
participant_allowed_source_address_prefixes = ["203.0.113.0/24"]
organizer_allowed_source_address_prefixes   = ["203.0.113.10/32"]
```

## 3. 基盤を作成

```bash
terraform init
terraform plan
terraform apply
```

作成後、主な出力を確認します。

```bash
terraform output vm_public_ip
terraform output azuredevops_project_url
terraform output -json participant_repositories
terraform output -json tfstate_container_names
```

## 4. 各 repo に workshop テンプレートを初期 push

```bash
cd ../
chmod +x scripts/*.sh
./scripts/bootstrap-repos.sh
```

PowerShell:

```powershell
Set-Location ..
./scripts/bootstrap-repos.ps1
```

このスクリプトは [workshop/](./workshop/) の内容を、各参加者専用 repo の `main` に push します。`main` への push により、各 repo の Pipeline 初回実行も発火します。

主催者は Azure DevOps ポータルで、各 Pipeline が成功することを確認します。

## 5. code-server 環境を生成・VM に配置

```bash
python3 scripts/gen-compose.py
SSH_KEY=~/.ssh/id_rsa ./scripts/deploy-to-vm.sh
```

PowerShell:

```powershell
python scripts/gen-compose.py
$env:SSH_KEY = "$HOME/.ssh/id_rsa"
./scripts/deploy-to-vm.ps1
```

生成物:

| ファイル | 内容 |
|----------|------|
| `docker/generated/docker-compose.yml` | 参加者数分の code-server 定義 |
| `docker/generated/.env` | code-server パスワードと Git PAT |
| `credentials/participants.csv` | 配布用 URL / パスワード / repo URL |

配布用の表示:

```bash
./scripts/print-handout.sh
```

PowerShell:

```powershell
./scripts/print-handout.ps1
```

## 6. 当日の説明ポイント

参加者に伝える流れ:

```bash
git checkout -b feature/workshop-change
# main.tf と variables.tf を編集
git add .
git commit -m "Update workshop setting"
git push -u origin feature/workshop-change
git checkout main
git merge feature/workshop-change
git push origin main
```

`main` に push した時点で Pipeline が起動し、Terraform `apply` が実行されます。参加者は Azure DevOps アカウントを持たないため、Pipeline 画面は主催者が画面共有で見せる想定です。

## 7. トラブルシューティング

| 症状 | 確認 |
|------|------|
| code-server に入れない | NSG、社内 FW、`docker compose ps` |
| repo clone に失敗 | `azuredevops_git_pat` のスコープ、PAT 有効期限、repo 権限 |
| Pipeline が起動しない | push 先が `main` か、`azure-pipelines.yml` が repo に存在するか |
| Terraform 認証エラー | Service Connection、SP の RBAC、Pipeline 変数 |
| backend init エラー | state Storage 名、参加者に対応する container 名、Service Connection の認証主体に対する Blob RBAC、backend の Azure AD 認証設定 |

この構成では、Managed Pool 自体ではなく Azure DevOps の Service Connection が Azure へ入る認証主体です。remote state を Blob で管理する場合は、Terraform backend を Azure AD 認証で初期化し、Service Connection の認証主体に state 用 Storage への `Storage Blob Data Contributor` を付与します。access key 方式のまま使う場合は `Microsoft.Storage/storageAccounts/listKeys/action` を含む `Storage Account Contributor` 以上が必要です。

## 8. 片付け

ワークショップ終了後:

```bash
ssh azureuser@<VM_IP> 'cd /opt/workshop/docker && sudo docker compose down'

cd 第三回/infra/terraform
terraform destroy
```

最後に以下を削除または失効します。

- `credentials/participants.csv`
- `docker/generated/.env`
- `azuredevops_git_pat`
- `azuredevops_pat`
