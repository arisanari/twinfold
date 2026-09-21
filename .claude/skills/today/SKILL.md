---
name: today
description: Twinfoldの「今日何する？」を決める。Notionスケジュールのフェーズ、docs/build-order.mdのDone、GitHub Project 5、コードの実状からPrimary E2Eの最も手前の未完了点を特定し、implementer agentへ渡せる粒度に分解する。日次の開始、次タスク、進捗レビュー、スコープ判断、Notion／Projectへの反映に使う。
---

# Today

Crypto World's Fair 2026におけるTwinfoldの実装責任者として、本体セッション（オーケストレーター）が使う。前提（正本の順序、守る規則、コマンド、委譲の型）は `AGENTS.md` を正とし、ここでは繰り返さない。

## Primary E2E

進捗はこのE2Eがどこまで通るかで判定する。UIが存在するだけでDoneにしない。

```text
実物と証拠を登録
→ devnet Assetをmint
→ walletがownershipを取得
→ My Collectionへ表示
→ iPhone ARで空間へPlace
→ provenanceをPull
→ 別walletへtransfer
→ 旧所有者からDisappear
→ 新所有者へAppear
→ Redeem Physicalを申請
→ 流通Assetをlock／retire
→ Passportへ来歴を残す
```

Vision Proはこの合格条件に含めない。iOSのE2Eが安定するまでVision Pro固有の作り込みをP0にしない。

## 開始時に読むもの

1. **Notionスケジュール**（`AGENTS.md` 第2節のURL）を `notion-fetch` で読み、今日がどのフェーズか、今週のbuild／GTMのDoneは何かを取る。Notionを読めない環境では `AGENTS.md` 第1節の開催期間から推定し、その旨を明記する。
2. `docs/build-order.md` で、そのフェーズのDoneと手順を確認する。
3. GitHub Project 5（`gh project item-list 5 --owner arisanari --format json`）から `In progress`、期限超過、次のP0を取る。
4. `git status`、該当コード、直近のbuild／test結果、Issue本文のDoneを確認し、`実データで完了`、`fixtureで完了`、`未実装`、`blocked` を区別する。文書だけ、Statusだけで進捗を推測しない。
5. Primary E2Eを先頭から辿り、最も手前の未完了点を今日の最優先にする。

## 回答の形

- **今日のゴール**: 終了時に触れる／見られる状態を一文で
- **最初の一手**: 今すぐ着手する一つ
- **今日のタスク**: 最大3件。順番、GitHub Issue、対象file／scene、Done、担当（implementer／本体／ユーザー）を含める
- **今日はやらない**: scope creepになりそうなもの
- **終了確認**: build、実機、test、録画、transaction等の証拠

「iOSを進める」のような抽象語で答えない。「fixture Asset 1点をAR sceneへ表示し、iPhone実機でtap Placeできる」のように書く。複数platformを並行せず、その日の終わりにPrimary E2Eが一段先まで通ることを優先する。

## 実行モード

ユーザーが着手を指示したら、説明で終えない。

1. 各タスクを `AGENTS.md` 第5節の「指示の型」に整えて `implementer` agentへ渡す。実機確認や権利判断など人にしかできない作業はユーザーへ依頼する。
2. 返ってきたdiffを本体が読み、必要なら `code-reviewer` と `build-verifier`（存在すれば）を回す。
3. fixtureと実データの境界が画面表示（`DEMO DATA`／`DEVNET`）と一致しているか確認する。
4. 結果、未接続部分、次の最初の一手を報告する。

本体が自分でコードを書くのは、implementerへの指示を書くより短く済む一行修正だけにする。

## GitHub Project 5の扱い

対象は `twinfold(solana×XR)`（fields: Status、Priority、Size、Milestone、Start date、Target date）。

- `Todo`: 未着手。調査だけでは変更しない。
- `In progress`: 実際に着手し、当日の作業対象になったもの。
- `Done`: Issue本文のDoneを満たし、build／test／実機／録画等の証拠を確認したもの。部分実装、fixtureだけ、未検証、blockerありはDoneにしない。

Statusは実作業に合わせて同期してよい。Priority、Milestone、日付は既存計画から機械的に整合させられる場合だけ更新する。期限変更、P0からの降格、Issueの新規作成・削除、別repositoryの変更は推奨案を示してユーザーの了承を得る。

進捗確認時は次の不一致を報告する: `Done` だが証拠がない、`Todo` だが実装済み、Issue本文が現在の計画より古い（Vision Pro前提・原画前提・切手beachhead前提・棚に飾るコレクティブルbeachhead前提のものを含む）、Target dateが依存順序と矛盾、重複Issue、P0なのにPrimary E2Eにも安全性にも寄与しない。

## Notionへの反映

自動では書かない。ユーザーが「Notionに反映して」と言ったときだけ、親ページ（`AGENTS.md` 第2節）の末尾に次の一行ブロックを `insert_content` で追記する。

```text
- YYYY-MM-DD: 通ったE2E区間／今日のDone／blocker／次の最初の一手
```

週次のweekly updateはこのskillではなく `e2e-evidence` が扱う。既存ページの本文を書き換えない。

## 技術判断

- 期限内にAha moment（Place → Pull → Disappear）をiPhone実機で安定再現できる選択を優先する。
- cross-platform性はCore Model、Provider、Platform Adapterの境界で確保し、iPhoneの体験品質を落とさない。
- 新規architectureは今期のPrimary E2Eまたは安全性へ効く場合だけ導入する。
- 遅延時は機能を増やさずfallbackを選ぶ。切り替え表は `docs/build-order.md` を正とする。

顧客、事業モデル、Reference Assetの選定、権利判断など、プロダクトの方向を変える決定はユーザーの領域として扱い、選択肢・影響・推奨を添えて確認する。

## 完了報告

`AGENTS.md` 第6節の型に加え、implementerへ渡したタスクと結果、GitHub Projectで変更したStatus／field、検出した不一致を含める。
