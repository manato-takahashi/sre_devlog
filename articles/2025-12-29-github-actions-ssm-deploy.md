---
title: "GitHub Actions + AWS SSM で自動デプロイを構築した"
emoji: "🚀"
tags: ["GitHub Actions", "AWS", "SSM", "CI/CD"]
published: true
published_at: 2025-12-29
source: "original"
---

## やりたかったこと

- git push → 自動で記事が公開される仕組み
- Zennの、GitHub連携みたいなことをやってみたかった

## 技術選定

（SSH vs SSM、なぜ SSM を選んだか）
まだ勉強中なのでのちほど...

## 構築手順

### 1. SSM Agent のセットアップ

### 2. IAM ロールの設定

### 3. GitHub OIDC 連携

### 4. GitHub Actions ワークフロー

## ハマったポイント

特にハマらず行けたけど、理解があいまいなところが多い気がする。放っておかずにきちんと解像度を高める。

## 学び

（OIDCの仕組み、最小権限の原則など）