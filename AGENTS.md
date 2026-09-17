# Twinfold — AIエージェント共通ガイド

`CLAUDE.md` はこのファイルへのsymlink。Claude Code／Codexのどちらも、まずここを読む。

## 1. いま何を作っているか（2026-09-18時点）

- **Twinfold is the ownership layer for real-world collectibles, starting with vintage Japanese postage stamps.**
- 提出先: Crypto World's Fair 2026（Colosseum）。開催 2026-09-14〜2026-10-12、内部締切 10/11。
- Primary ClientはiPhone AR（Unity + AR Foundation + ARKit XR Plugin）。Apple Vision ProはHero／secondary（P1）で、既存 `apps/visionos` はfallback用に保持する。
- 2026-09-11にbeachheadをアニメ原画から切手へ切り替えた。「原画」「Vision Pro実機がMVP」と書かれた文書・コード・Issueは古い。見つけたら直す前に指摘する。
- Webはwallet、取引、redeem、比較Timeline。Spatial ClientはPlace／Unfold／Pull／Appear／Disappear。

## 2. 正本の置き場と読む順

実装に必要なものはrepo、戦略・日程・需要検証はNotionに置く。矛盾があれば上位を優先し、矛盾そのものを報告する。戦略を勝手に決め直さない。

### repo（毎回読む）

1. [docs/mvp.md](docs/mvp.md) — P0、必須E2E、合格基準、Out of Scope、提出物
2. [docs/build-order.md](docs/build-order.md) — 実装フェーズ、各フェーズのDone、Definition of Done、blocker時の切り替え
3. [docs/architecture.md](docs/architecture.md) — 責務境界、共通モデル、Provider、認証・Entitlement、同期
4. GitHub Project 5 `twinfold(solana×XR)` — 実行中タスクのStatusと日付（https://github.com/users/arisanari/projects/5/views/4）

### Notion（戦略・日程・GTMを確認するとき）

親ページ: https://app.notion.com/p/3de2b198e4f4800cafc1c7ac9d3bb465

- スケジュール（週別カレンダー）: https://app.notion.com/p/3de2b198e4f4814dafa8ce10241a0925
- PRD（Positioning、顧客、なぜSolana／Spatial／切手、事業モデル）: https://app.notion.com/p/3de2b198e4f4812ea49ce250b0d3b334
- GTM実行計画（需要検証、Pitch）: https://app.notion.com/p/3de2b198e4f481c7a944dcad01ef9fd0
- Supplier List: https://app.notion.com/p/3de2b198e4f481d7affdcd1f1d9ec768
- 外部サービス・アカウント台帳: https://app.notion.com/p/3de2b198e4f4810e9854daf4794dc916

Notionを読めない環境では、第1節の要約を前提として進め、戦略に関わる判断はユーザーへ確認する。Notionの `最終更新` が2週間以上古い場合は、内容を使う前に指摘する。

`README.md` は公開向けの要約で正本ではない。正本を変えたらREADMEも合わせる。`.env.colosseum/` はgit管理外のローカルメモで、`archive/` 以下は参照専用。

## 3. 必ず守る規則

- UI（Web／Unity／Swift）からSolana RPC／DASを直接呼ばない。`AssetProvider`（Mock／Solana）経由にする。
- `MockAssetProvider` と `SolanaAssetProvider` は同じ共通モデルを返す。fixtureは画面に `DEMO DATA`、実接続は `DEVNET` と表示する。
- platform固有処理（camera、平面検出、anchor、touch）はPlatform Adapterに隔離する。
- transfer／redeemは `pending` → `confirmed`／`failed` を区別し、transaction signatureまたはrequest IDで冪等化する。
- 秘密鍵、APIキー、配送先などの個人情報、権利未確認の画像をrepo・log・動画に入れない。`HELIUS_API_KEY` を `NEXT_PUBLIC_` にしない。
- blockchain／NFT／Passportが真正性・著作権・配送後の現物状態を保証すると書かない。onchain fact、off-chain evidence、Twinfold interpretationを区別する。devnet transferを売上と呼ばない。
- mainnet、本番決済、実配送、有料契約、外部公開・提出は、ユーザー確認なしに行わない。
- Final Build以降は新機能を追加しない。
- 完了は機能の有無ではなく、Primary E2Eがどこまで通るかで判定する。`実データで完了`、`fixtureで完了`、`未実装`、`blocked` を区別する。

## 4. コード構成とコマンド

```text
apps/web/       Next.js 16 / React 19 / TypeScript。UIプロトタイプ（fixture）
apps/visionos/  SwiftUI + RealityKit。XcodeGen（project.yml）。P1 Hero Demo
apps/unity/     未作成。Unity + AR Foundation。P0 iPhone AR
docs/           実装側の正本（mvp、build-order、architecture）
.env.colosseum/ ローカル専用メモ（git管理外）
```

- Web: `cd apps/web && npm install && npm run dev`。検証は `npm run build` と `npm run lint`
- Web env: `apps/web/.env.example` を `apps/web/.env.local` にコピーして実値を入れる
- visionOS: `cd apps/visionos && xcodegen generate && open TwinfoldVision.xcodeproj`

## 5. エージェントとskillの置き場

実体は `.claude/` に置く。`.agents/skills/*` と `CLAUDE.md` はsymlink。

- `.claude/skills/twinfold-hackathon-engineer` — 「今日何する」、実装、進捗レビュー、GitHub Project同期
- `.claude/agents/code-reviewer` — 読み取り専用のコードレビュー

## 6. 完了報告の型

今日通ったE2Eの区間、変更したfile、実行した検証と結果、fixture／未接続／既知の制約、次回の最初の一手。
