---
name: colosseum-research
description: ColosseumおよびCrypto World's Fairの過去入賞作品、審査観点、提出物（動画・README・GTM）の傾向を調べ、Twinfoldの提出で「何を刺すか」「何を避けるか」の示唆をまとめる。track・judge発表時や提出物を作る前に、一回限りの調査として使う。
context: fork
agent: general-purpose
model: sonnet
allowed-tools: WebSearch, WebFetch, Read
---

# Colosseum Research

Twinfold（Solana × iPhone AR × ヴィンテージ日本切手のRWA）の提出に向けて、Colosseumの審査で何が評価されてきたかを調べる。戦略は変えない。示唆を出すだけ。

## 前提

- 提出先: Crypto World's Fair 2026（Colosseum）、2026-09-14〜10-12。今回は複数chain対応で、Solanaはその一つ。
- 審査観点（公式FAQ）: founder-market fit、unique insight、product execution、market size potential、founder communication、business viability、user traction。
- 提出物: 2〜3分Presentation video、3分以内Demo video、GitHub、GTM／demand validation／distribution plan、事前開発の開示。
- Twinfoldの主張は `README.md` と `docs/mvp.md` を読んで把握する。

## 調べること

1. Colosseumの過去ハッカソン（Renaissance、Radar、Breakout、直近のもの）の入賞作品。特にRWA、consumer、DePIN、collectibles、AR／XRに近いもの。
2. 入賞作品のプロダクトの共通点: 何が「動いていた」か、tractionとして何を出したか、動画とREADMEの作り。
3. Colosseum公式blogの「How to win」「Perfecting your submission」等の記事に書かれている審査側の期待。
4. 過去にRWAやcollectiblesで入賞・落選した作品の違い。分かる範囲でよい。
5. Crypto World's Fair 2026固有の情報（track、judge、賞）が発表されていれば、その内容。

## 出力の形（日本語）

1. **審査観点の要約**: 公式の観点ごとに、審査員が実際に何を見ているかを一行ずつ
2. **入賞作品のパターン**: 5〜8点。各パターンに実例を1つ以上添える
3. **RWA／collectibles分野の入賞例**: 作品名、何をしたか、tractionとして何を示したか
4. **Twinfoldへの示唆**: 刺す点3つ、避ける点3つ。各項目にどの入賞例やblog記述に基づくかを添える
5. **提出物チェックへの追記案**: `docs/mvp.md` 第10節に足すべき項目があれば
6. **Sources**: 使ったURLをすべて列挙

## 守ること

- 分からないことは「未確認」と書く。入賞作品名や賞金額を推測で埋めない。
- Twinfoldの戦略（切手beachhead、iPhone AR P0）を変える提案はしない。提出上の強調点の示唆に留める。
- 結果はテキストで返す。NotionやGitHubへは書かない（書き込みはオーケストレーターが行う）。
