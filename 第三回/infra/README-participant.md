# 参加者向け README

第三回では、ブラウザ上の VS Code（code-server）で Terraform ファイルを編集し、Git の `feature` ブランチを `main` に merge して push します。`main` に push すると Azure Pipelines が自動で Terraform を実行します。

Azure / GitHub / Azure DevOps アカウントは不要です。

## 受け取るもの

| 項目 | 例 |
|------|-----|
| code-server URL | `http://20.x.x.x:8001` |
| パスワード | 主催者から配布 |
| repo | 自分専用の Azure Repos リポジトリ |

## 1. code-server に接続

1. ブラウザで配布された URL を開く
2. パスワードを入力
3. VS Code 画面が表示されることを確認

`~/workshop` には自分専用 repo が clone 済みです。

## 2. 作業ブランチを作成

VS Code のターミナルで実行します。

```bash
cd ~/workshop
git status
git checkout -b feature/workshop-change
```

## 3. Terraform を編集

`variables.tf` の `display_name` を自分の名前に変更します。

```hcl
variable "display_name" {
  type        = string
  description = "Handson: set your name here (used in resource tags and workshop change)."
  default     = "your-name"
}
```

次に `main.tf` の TODO を探し、コメントを外します。

```hcl
# "WORKSHOP_CHANGE" = var.display_name
```

以下のようにします。

```hcl
"WORKSHOP_CHANGE" = var.display_name
```

## 4. feature ブランチへ commit / push

```bash
git add .
git commit -m "Update workshop setting"
git push -u origin feature/workshop-change
```

この時点では Terraform `apply` は実行されません。

## 5. main に merge して push

```bash
git checkout main
git merge feature/workshop-change
git push origin main
```

`main` に push すると Azure Pipelines が起動し、Terraform `apply` が自動で実行されます。

## 6. 結果確認

Pipeline の実行画面は主催者が画面共有で確認します。成功後、App Service URL にアクセスすると `workshop_change` に自分の `display_name` が表示されます。

## 注意事項

- ローカルで `terraform apply` は実行しません。
- 自分に配布された code-server URL 以外は使わないでください。
- `main` へ push した時点で Azure 上のリソースが変更されます。
- エラーが出たら、実行したコマンドとエラーメッセージを主催者に伝えてください。
