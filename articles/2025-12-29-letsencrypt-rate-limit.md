---
title: "Let's Encryptのレートリミットにハマった話"
emoji: "🔒"
tags: ["SRE Devlog", "Let's Encrypt", "Docker", "Thruster", "Rails"]
published: true
published_at: 2025-12-29
source: "original"
---

## 何が起きたか

Docker のボリューム設定を修正する際に、誤ってボリュームを削除してしまった。

その結果、Thruster がキャッシュしていた Let's Encrypt の証明書が消失。再起動時に証明書を再取得しようとしたが、**レートリミットに引っかかって HTTPS が使えなくなった**。

## Let's Encrypt のレートリミット

| 制限                       | 内容              |
| -------------------------- | ----------------- |
| 同一ドメインへの証明書発行 | 7 日間で 5 回まで |
| 失敗したリクエスト         | カウントされない  |
| 更新（同じ証明書）         | 制限なし          |

つまり、短期間に証明書を何度も新規発行すると制限がかかる。

今回は、ボリューム削除 → コンテナ再起動を繰り返したことで、証明書の新規発行が複数回発生してしまった。

## Thruster の証明書キャッシュ

Thruster（Rails 8 のデフォルト HTTP プロキシ）は、Let's Encrypt の証明書を自動で取得・管理してくれる。

証明書は `./storage/thruster` に保存される（デフォルト）。

```
/rails/storage/          ← ボリュームでマウントすべき場所
└── thruster/
    └── (証明書ファイル)
```

このディレクトリを永続化しないと、コンテナ再起動のたびに証明書を再取得することになる。

## 正しい compose.yaml の設定

```yaml
services:
  web:
    volumes:
      - storage_data:/rails/storage # ← これが重要

volumes:
  storage_data:
```

`/rails/storage` を名前付きボリュームでマウントすることで：

- SQLite のデータが永続化される
- Thruster の証明書キャッシュも永続化される
- コンテナを再起動しても証明書を再取得しなくて済む

## 復旧方法

レートリミットにかかったら、**1 週間待つしかない**。

その間の選択肢：

| 選択肢           | メリット           | デメリット          |
| ---------------- | ------------------ | ------------------- |
| HTTP で公開      | すぐ動く           | セキュリティ警告    |
| 待つ             | 何もしなくていい   | アクセスできない    |
| ALB + ACM に移行 | レートリミットなし | 月 $20 程度のコスト |

今回は、あまり慣れていない個人開発でセキュリティにも懸念があるし、すぐに公開したい需要もなかったので安全策を取って HTTPS 復活まで待つことにした。
そのため、いったん EC2 インスタンスは停止して、動作確認はすべてローカルで行うことに。

## EC2 停止時の注意

復旧を待つ間、EC2 を停止しておくとコスト節約になる。

| 状態   | EC2 課金 | Elastic IP 課金        |
| ------ | -------- | ---------------------- |
| 起動中 | あり     | あり（2024 年 2 月〜） |
| 停止中 | なし     | あり                   |

**注意**: Elastic IP はインスタンス停止中でも課金される（約 $0.005/時 = $3.6/月）。

ただし、ボリュームはインスタンス停止しても消えないので、再起動後にレートリミットが解除されていれば HTTPS は復活する。

## 学び

- ボリュームの削除は慎重に...（特にキャッシュ系で消したらまずいものがないか調べてから）
- 証明書のキャッシュ場所や Let's Encrypt のレート制限について理解しておく

## 参考

- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Thruster GitHub](https://github.com/basecamp/thruster)
- [AWS Public IPv4 Address Charge](https://aws.amazon.com/blogs/aws/new-aws-public-ipv4-address-charge-public-ip-insights/)
