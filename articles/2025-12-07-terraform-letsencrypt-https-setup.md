---
title: "Terraform + Let's Encryptで学ぶ、HTTPS環境構築の全体像"
emoji: "🔒"
tags: ["terraform", "nginx", "letsencrypt", "aws"]
published: true
published_at: "2025-12-07"
source: "zenn"
source_url: "https://zenn.dev/manamana/articles/terraform-letsencrypt-https-setup"
html_body: "true"
---

## 結論（TL;DR）

nginx + certbot で HTTPS 化する流れを理解した。certbot が nginx 設定を自動で書き換えてくれるので、手順自体はシンプル。ポート80を開けておく必要があるのは Let's Encrypt の認証のため。

---

## 1. はじめに

### 作るもの

```
ブラウザ
  ↓ HTTPS (443)
nginx（SSL終端 + リバースプロキシ）
  ↓ HTTP (5000)
Redash（Docker Compose）
```

ドメインは Route 53 で取得、インフラは Terraform で管理、証明書は Let's Encrypt で無料取得。

### なぜこの構成か

「HTTPS化」はよく出てくるタスクだけど、実際に手を動かさないと理解しにくい。今回は学習目的で、以下を一通り体験する：

- Terraform でのインフラ構築（EC2, VPC, Route 53）
- nginx のリバースプロキシ設定
- certbot による証明書取得の流れ

本番運用なら ALB + ACM を使う方がシンプルだが、「中で何が起きてるか」を理解するにはこの構成が最適。

---

## 2. 全体像を理解する

### HTTP vs HTTPS

|        | HTTP | HTTPS  |
| ------ | ---- | ------ |
| ポート | 80   | 443    |
| 通信   | 平文 | 暗号化 |
| 証明書 | 不要 | 必要   |

HTTPS = HTTP + TLS（暗号化レイヤー）。証明書がないとブラウザが「安全ではありません」と警告を出す。

### nginx の役割：リバースプロキシ

Redash 自体は HTTPS に対応していない。そこで nginx を「受付係」として前に置く：

```
ブラウザ → nginx（HTTPS受付、証明書処理）→ Redash（HTTP）
```

nginx が暗号化/復号化を担当し、Redash には普通の HTTP で転送する。この構成を「SSL終端」と呼ぶ。

### Let's Encrypt の仕組み

Let's Encrypt は無料で SSL 証明書を発行してくれる認証局（CA）。

**認証の流れ（HTTP-01チャレンジ）：**

```
1. certbot が Let's Encrypt に「redash.sre-lab.click の証明書ください」と申請
2. Let's Encrypt が「じゃあ http://redash.sre-lab.click/.well-known/acme-challenge/xxx にファイル置いて」と返す
3. certbot がファイルを配置
4. Let's Encrypt がアクセスして確認 → 本当にこのドメインの管理者だと証明
5. 証明書発行！
```

だからポート80を外部公開しておく必要がある（Let's Encrypt のサーバーがアクセスしてくるから）。

[チャレンジの種類 - Let's Encrypt](https://letsencrypt.org/ja/docs/challenge-types/)

---

## 3. 事前準備

### ドメイン取得（Route 53）

AWS コンソールから Route 53 → ドメインの登録で取得。今回は `sre-lab.click`（$3/年）を選択。

取得完了するとホストゾーンが自動作成される。

### Terraform でインフラ構築

VPC、サブネット、セキュリティグループ、EC2、Route 53 レコードを一括管理。

**セキュリティグループのポイント：**

```hcl
# SSH - 自分のIPのみ
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["xxx.xxx.xxx.xxx/32"]
}

# HTTP - Let's Encrypt認証用に全開放
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# HTTPS - 本番アクセス用
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

80番を全開放するのは、Let's Encrypt のサーバーがランダムな IP からアクセスしてくるため。

**Route 53 レコード：**

```hcl
resource "aws_route53_record" "redash" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "redash.sre-lab.click"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redash.public_ip]
}
```

`terraform apply` で EC2 の Public IP が自動で DNS に登録される。

---

## 4. 実践：HTTPS化の手順

### Step 1: nginx & certbot インストール

```bash
sudo dnf install -y nginx certbot python3-certbot-nginx
```

### Step 2: nginx 設定（まず HTTP で疎通確認）

```bash
sudo tee /etc/nginx/conf.d/redash.conf << 'EOF'
server {
    listen 80;
    server_name redash.sre-lab.click;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

**設定の意味：**

| 行            | 意味                             |
| ------------- | -------------------------------- |
| `listen 80`   | ポート80で待ち受け               |
| `server_name` | このドメイン宛のリクエストを処理 |
| `location /`  | 全てのパスが対象                 |
| `proxy_pass`  | Redash（5000番）に転送           |

```bash
sudo nginx -t          # 文法チェック
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 3: HTTP 疎通確認

```bash
curl -I http://localhost
# HTTP/1.1 200 OK が返ればOK
```

### Step 4: certbot で証明書取得

```bash
sudo certbot --nginx -d redash.sre-lab.click
```

対話形式で進む：

1. メールアドレス入力（更新通知用）
2. 利用規約に同意（Y）
3. ニュースレター購読（N でOK）

成功すると：

```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/redash.sre-lab.click/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/redash.sre-lab.click/privkey.pem
```

### Step 5: 自動で書き換わった設定を確認

certbot が nginx 設定を自動更新してくれる：

```nginx
# HTTPS用（certbotが追加）
server {
    server_name redash.sre-lab.click;
    location / { ... }  # 元のまま

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/redash.sre-lab.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/redash.sre-lab.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

# HTTPリダイレクト用（certbotが追加）
server {
    listen 80;
    server_name redash.sre-lab.click;

    if ($host = redash.sre-lab.click) {
        return 301 https://$host$request_uri;
    }
    return 404;
}
```

**追加された内容：**

| 設定                    | 役割                          |
| ----------------------- | ----------------------------- |
| `listen 443 ssl`        | HTTPS で待ち受け              |
| `ssl_certificate`       | 証明書ファイルの場所          |
| `ssl_certificate_key`   | 秘密鍵の場所                  |
| 2つ目の server ブロック | HTTP → HTTPS 自動リダイレクト |

---

## 5. 動作確認 & トラブルシューティング

### 動作確認

ブラウザで `https://redash.sre-lab.click` にアクセス。🔒 鍵マークが表示されれば成功！

**コマンドラインで確認する場合：**

```bash
curl -I https://redash.sre-lab.click
# HTTP/2 200 が返ればOK
```

### よくあるエラーと対処

#### 証明書取得に失敗する

```
Challenge failed for domain redash.sre-lab.click
```

**原因と対処：**

| 原因                   | 対処                                             |
| ---------------------- | ------------------------------------------------ |
| ポート80が閉じている   | セキュリティグループで `0.0.0.0/0` を許可        |
| DNS が浸透していない   | `ping redash.sre-lab.click` で IP 確認、数分待つ |
| nginx が起動していない | `sudo systemctl status nginx` で確認             |

#### 502 Bad Gateway

nginx は動いてるが、転送先（Redash）に繋がらない。

```bash
# Redash が起動しているか確認
sudo docker-compose ps

# 全コンテナが Up になっているか
# Restarting が続いていたら logs を確認
sudo docker-compose logs server
```

#### メモリ不足でフリーズ

Redash は推奨 4GB 以上。t3a.small（2GB）だと起動時にフリーズすることがある。

```bash
free -h  # メモリ確認
# available が 1GB 以下なら厳しい
```

**対処：** t3a.medium（4GB）以上にインスタンスタイプを変更。

---

## 6. まとめ

### 学んだこと

- **nginx のリバースプロキシ**：HTTPS 非対応のアプリの前に置いて SSL 終端する構成
- **Let's Encrypt の認証フロー**：HTTP-01 チャレンジでドメイン所有を証明
- **certbot の便利さ**：nginx 設定を自動で書き換えてくれる
- **ポート設計の意図**：80 番を開けるのは Let's Encrypt 認証のため

### 構成の全体像（再掲）

```
ブラウザ
  ↓ HTTPS (443)
nginx（SSL終端 + HTTPリダイレクト）
  ↓ HTTP (5000)
Redash（Docker Compose）
  ├─ server
  ├─ scheduler
  ├─ worker
  ├─ PostgreSQL
  └─ Redis
```

### 本番運用との違い

今回の構成は学習目的だが、社内ツール用途ならほぼこのまま使える。

| 観点             | 今回（学習）         | 本番（社内ツール）                |
| ---------------- | -------------------- | --------------------------------- |
| SSL 証明書       | Let's Encrypt        | Let's Encrypt（同じ）             |
| リバースプロキシ | nginx                | nginx（同じ）                     |
| DB               | Docker 内 PostgreSQL | **RDS**（移行済み）               |
| コンテナ         | EC2 + Docker Compose | EC2 + Docker Compose or ECS + EC2 |

社内ユーザー限定・頻繁なデプロイなし・障害時は手動復旧で許容できるなら、ALB + ACM + Fargate はコスト的にオーバーキル。

**DB だけは RDS 推奨**：バックアップ、障害復旧、メンテナンスが圧倒的に楽になる。

### 次のステップ

- RDS 移行：DB を Docker 外に出して耐障害性向上
- ECS Fargate 化：EC2 管理をなくす
- CloudWatch 監視：証明書期限、ディスク使用率などをアラート設定

---

## 自分メモ

### ハマったポイント：

- ポート80（http）も全開放する必要がある点で少しハマった。Let's EncryptのサーバーがどのIPからアクセスしてくるかわからないため、開けておく必要がある。
- Redash が意外と多くのメモリを必要とした点も少しハマった。最初はt3a.microやt3a.smallで試行錯誤していたが、どうもコンテナ起動時や操作時にフリーズしてしまって不具合が発生することが多く、t3a.mediumに変更したら解決した。

### 次回気をつけること：

- 公式ドキュメントやコミュニティの情報を確認し、推奨スペックにあたりをつけてから構築する

### 関連して気になること：

- ECS + EC2などの構成にできると、比較的コストは抑えつつコンテナ自動復旧やデプロイ、スケーリングの自動化、ログ管理などが少しやりやすくなるみたい。ECS + Fargateにできるのがメンテナンスコスト面では最強だが、その分金銭的コストがかさんでしまうのでそのあたりのバランスを考慮したインフラ設計ができるようになりたい。