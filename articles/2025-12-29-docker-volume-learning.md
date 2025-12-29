---
title: "Dockerのボリュームを理解した話"
emoji: "🐳"
tags: ["SRE Devlog", "Docker", "Docker Compose", "SQLite", "Rails"]
published: true
published_at: 2025-12-29
source: "original"
---

## きっかけ

- ファイルアップロードした記事を同期する articles:sync の Rake タスクを作っていざ push！というところで、必要な migration がなぜか動かない
- よくよく見たら migration ファイル自体がないことに気づく → Docker が怪しいと思って調査
- Claude と一緒に調査していたら、やはりボリューム設定周りがおかしいことに気づく
- いつもボリューム周りの概念や設定に翻弄されてしまうので、一度徹底的に Claude に質問して理解を深めたので記事化

## 問題のあった設定

```yaml
# compose.yaml（修正前）
services:
  web:
    volumes:
      - ./storage:/rails/db # バインドマウント
      - db_data:/rails/db # 名前付きボリューム（同じパス！）
```

この設定には 2 つの問題があった。

### 問題 1: 同じパスに 2 つのボリューム

同じ `/rails/db` に 2 つマウントすると、後から書いた方（`db_data`）が優先される。最初の `./storage` は無視されてしまう。

### 問題 2: そもそもパスが間違っている

SQLite ファイルは `/rails/storage/` にあるのに、`/rails/db` をマウントしていた。

さらに `/rails/db` をボリュームで覆ってしまうと、`db/migrate/` が隠れてマイグレーションが動かなくなる可能性があった。

## ボリュームで「隠れる」とは

ここが最初ピンとこなかった。

Docker のボリュームマウントは「上から被せる」イメージ。

```
【ボリュームをマウントすると】

┌───────────────────────┐
│  db_data（空の箱）     │ ← 上から被せた
│  /rails/db/ = 空      │
└───────────────────────┘
┌───────────────────────┐
│  イメージの中身        │ ← 下に隠れた（見えない）
│  /rails/db/migrate/   │
└───────────────────────┘
```

イメージに焼き付けられたファイル（`db/migrate/` など）が、ボリュームに「隠されて」見えなくなる。

## イメージとコンテナの理解

ここも曖昧だったので整理した。

| 概念           | たとえ     | 特徴                                  |
| -------------- | ---------- | ------------------------------------- |
| **イメージ**   | CD-ROM     | `docker build` で作る。読み取り専用。 |
| **コンテナ**   | CD 再生中  | イメージから起動した実行状態。        |
| **ボリューム** | 外付け HDD | コンテナが消えてもデータが残る。      |

Dockerfile の `COPY . .` でファイルがイメージに「焼き付けられる」。コンテナはそのイメージをベースに動く。

## 修正後の設定

```yaml
# compose.yaml（開発用）
services:
  web:
    volumes:
      - storage_data:/rails/storage # SQLite永続化
      - ./articles:/rails/articles # 開発時の記事即時反映

volumes:
  storage_data:
```

```yaml
# compose.prod.yaml（本番用）
services:
  web:
    volumes:
      - storage_data:/rails/storage # SQLite永続化のみ

volumes:
  storage_data:
```

### 開発と本番の違い

| 環境 | バインドマウント  | 理由                                  |
| ---- | ----------------- | ------------------------------------- |
| 開発 | `./articles` あり | ホストで編集 → 即反映                 |
| 本番 | なし              | イミュータブル。git pull で取得済み。 |

## ボリュームの種類と使い分け

| 書き方           | 種類               | 用途                      |
| ---------------- | ------------------ | ------------------------- |
| `名前:/パス`     | 名前付きボリューム | DB 永続化など。本番向き。 |
| `./ホスト:/パス` | バインドマウント   | 開発時のコード共有。      |

トップレベルの `volumes:` は名前付きボリュームの「定義」。サービス内の `volumes:` は「使う」宣言。

## SQLite だから 1 コンテナで OK

MySQL/PostgreSQL なら DB は別コンテナにするのが普通。

でも SQLite は「ただのファイル」なので、同じコンテナ内で動かせる。今回の構成はシンプルで問題ない。

## 学び

- 「とりあえず動いてるぽいからいいや」は結局後で困る、遠回りになるのでちゃんと理解する
- Docker のイメージ、コンテナ、ボリュームについて理解できた
- Claude Desktop はコードベースの知識やコンテキストを持っていないので、やはり実装に関することは最初から Claude Code と会話しながら進めた方がこうした問題が起きにくいだろうなと感じた
- Claude に「学習目的だから全部やっちゃわないで、私の手を動かさせて」みたいな風にあらかじめ伝えておけば Claude Code を使っても学習しながら開発を進められそうなことが分かった

## 参考

- [Docker 公式 - Manage data in Docker](https://docs.docker.com/engine/storage/)
- [Docker 公式 - Volumes](https://docs.docker.com/engine/storage/volumes/)
