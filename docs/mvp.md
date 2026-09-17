# Twinfold MVP Acceptance Criteria

> 対象: Crypto World's Fair 2026
>
> 開催期間: 2026-09-14〜2026-10-12
>
> 最終更新: 2026-09-18

## 1. 役割

この文書は、Twinfoldを「動く技術作品」ではなく、real-world collectiblesのstartup MVPとして提出できるかを判定する。

- Why、顧客、事業: [Product Requirements（Notion）](https://app.notion.com/p/3de2b198e4f4812ea49ce250b0d3b334)
- 実装順と日程: [Build Order](./build-order.md)
- 技術設計: [Technical Architecture](./architecture.md)
- 現在の進捗: GitHub Project 5

Issueの完了数ではなく、E2E、実物、ユーザー証拠、提出物で判定する。

## 2. 提出時の主張

> **Twinfold is the ownership layer for real-world collectibles, starting with vintage Japanese postage stamps.**

> **Twinfold turns vaulted collectibles into transferable onchain ownership you can experience in space and redeem physically.**

MVPは、次を実証する。

1. 現物とオンチェーンAssetを明示的な証拠で接続できる
2. ownershipをwallet間で移転し、空間のAppear／Disappearへ反映できる
3. Vault保管された現物を、取り出さずに所有・鑑賞できる
4. redeem時に流通Assetを止め、二重流通を防げる
5. collectorとsupplierに解く価値の兆候がある

## 3. P0

- 権利上安全な実物の希少切手1点（クラシック切手または著作権が消滅した図案の記念切手）
- Asset登録、Physical情報、evidence、rights、custody
- Solana devnet上のMetaplex Core Asset
- wallet署名、owner取得、実transfer
- My Collection
- iOS AR（SwiftUI + RealityKit + ARKit）でのPlace、Pull、Appear／Disappear
- Vaulted／Physical Ownership
- redeem dry run、Asset失効、Provenance Passport
- collectorとsupplierの検証
- Presentation video、Demo video、README、GitHub

USDC purchaseはP0ではない。支払いとAsset移転をatomicに実装できた場合だけ追加する。

## 4. 必須E2E

~~~text
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
~~~

第三者が自分のiPhoneまたはテスト端末で操作代行なしに完走でき、fixtureとdevnetが明確に区別されること。Vision ProはHero／secondary demoであり、このE2Eの合格条件には含めない。

## 5. Product／Technical Acceptance

| 項目 | 合格条件 |
|---|---|
| Reference Asset | 権利、出所、状態、保管、表示範囲を記録した実物を最低1点用意する |
| Identity | Physical IDとdevnet Asset addressが一意に対応する |
| Wallet | 署名を検証し、秘密鍵を保存しない |
| Solana | mint、owner取得、transferを実transactionで確認できる |
| Collection | 現在ownerのAssetだけをMy Collectionへ表示する |
| iOS AR | SwiftUI／RealityKit／ARKit版が実機で起動し、camera、平面検出、配置が動く |
| Spatial | 初見ユーザーがPlaceとPullを実行できる |
| Transfer | confirmed後5分以内に旧ownerから消え、新ownerへ反映する |
| State | pending、confirmed、failedを区別し、失敗から復旧できる |
| Redeem | 申請後に流通Assetをlock／burn／retireし、二重移転を防ぐ |
| Passport | Vault退出までの来歴を残し、退出後のowner・状態を保証しない |
| Stability | 必須E2EをiPhone実機で3回連続成功できる |
| Transparency | fixtureは DEMO DATA、実接続は DEVNET と表示する |
| Reproduction | clean cloneからREADMEの手順でBuildまたはデモを再現できる |

## 6. Trust Acceptance

- onchain fact、off-chain evidence、Twinfold interpretationを区別する
- 現物所有権、著作権、Web／XR画像利用権を区別する
- blockchainが真正性や現在状態を自動保証するとは表現しない
- redeem後の現在ownerと現在状態をPassportが証明するとは表現しない
- 未確認、第三者主張、確認済みを同じ表示にしない
- 権利不明、現物不一致、二重申請時は処理を停止できる

## 7. Demand Validation

### 最低ライン

- Collector interviewまたは実機テスト: 10名以上
- Supplier interview: 3者以上
- OnboardしたReference Asset: 1点以上
- 第三者によるdevnet ownership transfer: 1件以上
- 問題、購入意向、Vault保管、redeemについて具体的な学び: 5件以上

### 勝ちライン

- 実証協力、Asset提供、購入予約等のsupplier／collector intent: 1件以上
- Waitlist: 50名
- Reference Asset: 3点
- 法務・権利・決済を整理した実取引: 1件

Waitlistと実取引は勝ちラインであり、Working Demoを遅らせない。devnet transferを売上または実売とは呼ばない。

## 8. Spatial Hypothesis

同じAssetと情報をWebとiOS ARで提示し、順序を参加者間で入れ替える。Vision Proは補助的な定性評価として分けて記録する。

| 指標 | 合格基準 |
|---|---|
| Comprehension | 80%以上が現在ownerと主要な移転を正しく説明できる |
| Ownership Salience | 60%以上が取得・移転を自分の状態変化として感じる |
| Trust | 80%以上が来歴、状態、証拠の範囲を正しく説明できる |
| Spatial Advantage | 60%以上が空間体験の具体的価値を自分の言葉で説明できる |

少人数の結果から統計的有意性は主張しない。

## 9. Out of Scope

- mainnetと本番資金移動
- 非atomicなUSDC送金を購入として見せること
- 海外配送、保険、re-vaultの本番運用
- 真正性、著作権、値上がり、投資価値の保証
- full marketplace、auction、offer、Discovery
- 複数chain、複数category、Vision Pro本番品質、Quest／Android製品版

## 10. World’s Fair Submission

- [ ] 2〜3分のPresentation video
- [ ] 3分以内のProduct Demo video
- [ ] Product名と短い説明
- [ ] 使用chain・tool一覧
- [ ] Team、所在地、Founder–Market Fit
- [ ] Logoまたはproduct graphic
- [ ] GitHub repositoryと再現手順
- [ ] Go-to-market、demand validation、distribution plan
- [ ] 期間前の既存コードと、9/14〜10/12に完成した作業の開示
- [ ] 1分以内のweekly updateを可能な限り提出
- [ ] Demo video内でDemand Validationの数値（interview件数、waitlist等）を画面表示する
- [ ] Pitch videoはteam／problem／target user／traction、Demo videoはtech stack／Solana統合／機能ウォークスルーに役割を分ける
- [ ] Founder–Market Fitとして、切手ドメインでの接点やsupplier／collectorとの会話を1〜2件ナレーションに入れる
- [ ] 10/11を内部締切として提出内容を確認

## 11. Go／Conditional Go／Pivot

**Go:** 必須E2E、Product／Technical、Trust、Demand Validation最低ラインを満たし、Spatial指標が基準以上。

**Conditional Go:** E2Eと安全性は成立するが、需要またはSpatial指標の一部が未達。原因と次の検証を説明できる。

**Pivot:** 現物とAssetの安全な対応を作れない、ownership移転とredeemの二重流通を防げない、または改善後もSpatial Experienceの価値が伝わらない。

## 12. 完成証拠

- [ ] Reference Asset recordと利用許諾
- [ ] Asset address、mint／transfer transaction
- [ ] wallet認証とowner判定のテスト
- [ ] iOS AR BuildとE2E録画
- [ ] 可能ならVision Pro Hero Demo録画
- [ ] 3回連続成功logと表示失効時間
- [ ] redeem／Passport dry run
- [ ] interview記録と匿名化テスト結果
- [ ] supplier／collector intentの記録
- [ ] clean clone再現結果
- [ ] 既知の制約、未実装、事前開発の開示

必須項目が揃った時点をHackathon MVP完成とする。

## 13. 公式ソース

- [Crypto World’s Fair](https://colosseum.com/worldsfair)
- [Hackathon FAQ／提出・審査要件](https://colosseum.com/hackathon?year=fall2026)
- [World’s Fair発表](https://blog.colosseum.com/expanding-the-arena/)

9月14日にtrack、judge、賞、最終ルールを再確認し、本書の提出項目だけを更新する。
