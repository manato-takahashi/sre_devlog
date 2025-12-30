---
title: "Markdown記法テスト"
emoji: "🧪"
tags: ["テスト", "Markdown"]
published: false
published_at: 2025-12-30
source: "original"
---

## 見出し (Headings)

### h3 見出し

#### h4 見出し

##### h5 見出し

## テキスト装飾

これは **太字** と *斜体* と ~~取り消し線~~ のテストです。

**太字の中に*斜体*を含める**ことも可能です。

## リスト

### 順序なしリスト

- 項目1
- 項目2
  - ネストした項目2-1
  - ネストした項目2-2
    - さらにネスト
- 項目3

### 順序付きリスト

1. 最初の項目
2. 2番目の項目
   1. ネストした番号付き
   2. ネストした番号付き
3. 3番目の項目

### タスクリスト (GFM)

- [x] 完了したタスク
- [ ] 未完了のタスク
- [ ] もう一つの未完了タスク

## 引用

> これは引用です。
> 複数行にまたがることもできます。
>
> > ネストした引用も可能です。

## リンクと画像

[SRE Devlog トップ](/)

自動リンク: https://github.com

![プレースホルダー画像](https://placehold.co/600x200/2d333b/adbac7?text=Sample+Image)

## テーブル

| コマンド | 説明 | 例 |
|---------|------|-----|
| `ls` | ファイル一覧 | `ls -la` |
| `cd` | ディレクトリ移動 | `cd /var/log` |
| `grep` | 文字列検索 | `grep "error" app.log` |
| `docker ps` | コンテナ一覧 | `docker ps -a` |

## コードブロック

### Ruby

```ruby
class ArticleParser
  def initialize(markdown)
    @markdown = markdown
  end

  def parse
    Commonmarker.to_html(@markdown, options: {
      extension: { strikethrough: true, table: true }
    })
  end
end
```

### YAML

```yaml
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - storage_data:/rails/storage
    environment:
      RAILS_ENV: production

volumes:
  storage_data:
```

### Bash

```bash
#!/bin/bash

echo "Hello, SRE!"

# Dockerコンテナを起動
docker compose up -d

# Kubernetesでpodを確認
kubectl get pods -n production

# ログを確認
tail -f /var/log/app.log | grep --color=auto "ERROR"
```

### JavaScript

```javascript
const fetchArticles = async () => {
  try {
    const response = await fetch('/api/articles');
    const data = await response.json();
    return data.articles;
  } catch (error) {
    console.error('Failed to fetch articles:', error);
    throw error;
  }
};
```

### JSON

```json
{
  "status": "healthy",
  "uptime": "99.99%",
  "incidents": [],
  "metrics": {
    "requests_per_second": 1500,
    "latency_p99_ms": 45
  }
}
```

### SQL

```sql
SELECT
  articles.title,
  articles.published_at,
  COUNT(views.id) as view_count
FROM articles
LEFT JOIN views ON articles.id = views.article_id
WHERE articles.published = true
GROUP BY articles.id
ORDER BY view_count DESC
LIMIT 10;
```

## インラインコード

`kubectl get pods` でPodの一覧を確認できます。

環境変数 `RAILS_ENV` を `production` に設定してください。

## 水平線

上のセクション

---

下のセクション

## 脚注 (GFM)

SREとはSite Reliability Engineering[^1]の略で、Googleが提唱した概念です。

Dockerはコンテナ技術[^2]を利用した仮想化プラットフォームです。

[^1]: サイト信頼性エンジニアリング。運用とソフトウェアエンジニアリングを融合させたアプローチ。

[^2]: OSレベルの仮想化により、軽量で高速な実行環境を提供する技術。

## 複合テスト

以下は複数の要素を組み合わせたテストです：

> **注意**: `production` 環境では以下のコマンドを実行する前に、必ずバックアップを取得してください。
>
> ```bash
> pg_dump -h localhost -U postgres mydb > backup.sql
> ```

| 環境 | ポート | 備考 |
|------|--------|------|
| `development` | 3000 | ホットリロード有効 |
| `production` | 80/443 | SSL必須 |

## ターミナル風コードブロック

bashコードブロックは自動的にターミナル風UIになります。

```bash
docker compose up -d
kubectl get pods -n production
curl -X GET https://api.example.com/health
```

## おわり

以上がMarkdown記法のテストです。すべての要素が正しく表示されていることを確認してください。
