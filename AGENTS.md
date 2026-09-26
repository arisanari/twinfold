# Twinfold — AIエージェント共通ガイド

`CLAUDE.md` はこのファイルへのsymlink。Claude Code／Codexのどちらも、まずここを読む。

## 1. いま何を作っているか（2026-09-21時点）

- **Twinfold is the ownership layer for real-world collectibles. Beachhead: display collectibles, starting with ukiyo-e prints on your wall.**
- 最初の供給とデモは江戸・明治の浮世絵・古版画（著作権消滅、国際的なディーラー・オークション・状態評価〈摺り、退色、裏打ち、トリミング〉が確立、原摺りは新規供給がない、退色リスクがあるのでVault保管と壁での鑑賞がトレードオフになる、贋作・後摺りが多いので来歴と状態の記録を分けて残す価値がある）。
- Spatial promise: 買った瞬間に、自分の壁に掛かる。現物はVaultのまま。売れば壁から消える。保管中に買った物が、手元の実物コレクション（本物の額装作品）の隣に違和感なく並ぶのが中核体験。
- 拡張（次）: 棚（shelf）= フィギュア（メーカー公認3D前提、Metaplex Core royaltyで還元する未検証の仮説）と郷土玩具・伝統こけし（3D twinの例として2件目のfixtureに残す）。切手は履歴にだけ残す。
- 提出先: Crypto World's Fair 2026（Colosseum）。開催 2026-09-14〜2026-10-12、内部締切 10/11。
- Primary ClientはiPhone AR（SwiftUI + RealityKit + ARKit、`apps/ios`）。Apple Vision Pro（`apps/visionos`）はHero／secondary（P1）で、同じSwift Package `packages/TwinfoldCore` を使う。2026-09-18にUnityから切り替えた。
- beachhead変更履歴: アニメ原画（〜2026-09-11）→ 切手（2026-09-11〜2026-09-21）→ 棚に飾るコレクティブル（2026-09-21、同日中に見直し）→ 壁に掛ける浮世絵・版画（2026-09-21確定）。**提出までのbeachhead変更はこれが最後で、以後は変更しない。**「切手がbeachhead」「棚に飾るコレクティブルがbeachhead」「原画」「Vision Pro実機がMVP」「Unity／AR Foundation」と書かれた文書・コード・Issueは古い。見つけたら直す前に指摘する。切手は履歴にだけ残り、棚（フィギュア・こけし・郷土玩具）は拡張カテゴリとして残る。
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
- PRD（Positioning、顧客、なぜSolana／Spatial／浮世絵、事業モデル）: https://app.notion.com/p/3de2b198e4f4812ea49ce250b0d3b334
- GTM実行計画（需要検証、Pitch）: https://app.notion.com/p/3de2b198e4f481c7a944dcad01ef9fd0
- Supplier List: https://app.notion.com/p/3de2b198e4f481d7affdcd1f1d9ec768
- 外部サービス・アカウント台帳: https://app.notion.com/p/3de2b198e4f4810e9854daf4794dc916

Notionを読めない環境では、第1節の要約を前提として進め、戦略に関わる判断はユーザーへ確認する。Notionの `最終更新` が2週間以上古い場合は、内容を使う前に指摘する。

`README.md` は公開向けの要約で正本ではない。正本を変えたらREADMEも合わせる。`.env.colosseum/` はgit管理外のローカルメモで、`archive/` 以下は参照専用。

## 3. 必ず守る規則

- UI（Web／iOS／visionOS）からSolana RPC／DASを直接呼ばない。`AssetProvider`（Mock／Solana）経由にする。
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
apps/ios/       SwiftUI + RealityKit + ARKit。XcodeGen。P0 iPhone AR
packages/TwinfoldCore/  iOSとvisionOSで共有するSwift Package（共通モデル、Provider、Spatial Entity）
docs/           実装側の正本（mvp、build-order、architecture）
.env.colosseum/ ローカル専用メモ（git管理外）
```

- Web: `cd apps/web && npm install && npm run dev`。検証は `npm run build` と `npm run lint`
- Web env: `apps/web/.env.example` を `apps/web/.env.local` にコピーして実値を入れる
- iOS: `cd apps/ios && xcodegen generate` の後、`ios-realitykit-ar` skill の `xcodebuild` コマンド
- visionOS: `cd apps/visionos && xcodegen generate && open TwinfoldVision.xcodeproj`
- 共通Package: `cd packages/TwinfoldCore && swift build`

## 5. 役割分担と委譲（クレジット運用）

本体セッション（オーケストレーター、通常はFable）は判断・分解・最終レビューだけを行い、手を動かす作業はSonnet／Haikuのagentへ委譲する。

- **本体がやること**: `today` で今日を決める、implementerへの指示を書く、返ってきたdiffを読む、ユーザーへの確認、Notion／GitHub Projectへの書き込み。
- **本体がやらないこと**: 複数fileにまたがる実装、build／lintの実行、文書の矛盾検査、文言検査。これらはagentに回す。
- **本体が自分でコードを書いてよい例外**: implementerへの指示を書くより短く済む一行修正。

### implementerへ渡す指示の型

```text
対象: apps/web/lib/contract.ts と fixtures/demo/assets.json
期待結果: 浮世絵Reference Asset 1点がTwinfoldAsset型で定義され、Webの一覧に DEMO DATA ラベル付きで表示される
確認方法: cd apps/web && npm run build が成功し、npm run dev で /collection に1件表示される
境界: apps/visionos と apps/unity には触らない
```

### agent一覧

| agent | model | 役割 |
|---|---|---|
| `implementer` | sonnet | 指示された実装を行い、build を通してdiffと検証結果を返す。`core-contract`／`ios-realitykit-ar` を先読み |
| `code-reviewer` | sonnet | 境界、fixture区別、Entitlement、冪等性の読み取り専用レビュー |
| `ukiyoe-appraiser` | sonnet | 浮世絵の画像から落款・版元印・改印・判型を読み、所蔵館の記録と照合して背景を確度付きで返す調査メモ。鑑定ではない。`ukiyoe-domain` を先読み |
| `doc-consistency` | sonnet | README、docs/、AGENTS.md、Notion要約、Project 5 Issueの矛盾検出（未作成） |
| `claims-reviewer` | sonnet | UI文言、README、Pitch、Landingの禁止表現検査（未作成） |
| `build-verifier` | haiku | Web build／lint、iOS／visionOSの `xcodebuild`、`swift build` の結果だけ返す（未作成） |

### skill一覧

| skill | 実行 | 役割 |
|---|---|---|
| `today` | 本体 | 今日の分解、GitHub Project 5同期、Notionの読み書き |
| `core-contract` | implementerが読む知識 | 共通モデルとfixtureをWebとSwift Package（iOS・visionOS共有）で同時に整合させる手順 |
| `ios-realitykit-ar` | implementerが読む知識 | SwiftUI + RealityKit + ARKitのiPhone AR構成、共有Swift Package、build、実機チェック |
| `solana-devnet` | implementerが読む知識 | Metaplex Core、Helius DAS、Event正規化、test wallet |
| `ukiyoe-domain` | ukiyoe-appraiser／implementerが読む知識 | 落款・版元印・改印の読み方、判型と実寸、状態評価の語彙、照合先DB、画像の権利、fixtureへの対応と禁止表現 |
| `colosseum-research` | fork、sonnet | 入賞パターン調査。一回限り |
| `e2e-evidence` | fork、sonnet | E2E証拠収集、weekly update生成（未作成） |
| `submission` | fork、sonnet | 提出チェック、事前開発の開示、clean clone再現（未作成） |

実体は `.claude/` に置く。`.agents/skills/*` と `CLAUDE.md` はsymlinkで、Codexは同じskill本文を読む（model指定はCodex側の設定に従う）。

## 6. 完了報告の型

今日通ったE2Eの区間、変更したfile、実行した検証と結果、fixture／未接続／既知の制約、次回の最初の一手。
