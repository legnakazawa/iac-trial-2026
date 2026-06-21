# 完成形

ハンズオンの最終構成（答え合わせ・参照用）です。

## App Service に載るアプリ

`app/` に最小の Node.js（標準 `http` モジュールのみ）を置いています。

- `terraform apply` 時に `archive_file` で zip 化し、`zip_deploy_file` で Linux Web App にデプロイされます
- ブラウザで `web_app_url` を開くと、プレーンテキストで owner / Storage 名などが表示されます

```
IaC Workshop - Node sample
owner: user01
storage: stuser01xxxxxxxx
path: /
```

`app.zip` は apply 時に生成されます（`.gitignore` 済み）。

## 難易度別テンプレート

[`../README.md`](../README.md) を参照してください。
