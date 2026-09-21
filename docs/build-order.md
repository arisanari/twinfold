# Twinfold Build Order

> 最終更新: 2026-09-21
>
> 役割: 実装順、各フェーズのDone、Definition of Done、blocker時の切り替えを定義する。日付はNotionの[スケジュール](https://app.notion.com/p/3de2b198e4f4814dafa8ce10241a0925)とGitHub Project 5を正とし、ここには書かない。
>
> 関連文書: [Technical Architecture](./architecture.md)／[MVP Acceptance Criteria](./mvp.md)

## 1. Release Goal

提出時に、第三者がiPhoneで次を完走できる状態にする。

~~~text
実物と証拠を確認
→ devnet Assetをwalletで取得
→ My Collectionに現れる
→ iOS ARで部屋へPlace
→ provenanceをPull
→ 別walletへtransfer
→ 旧ownerからDisappear
→ Redeem Physicalを申請
→ Assetが失効しPassportが残る
~~~

Apple Vision ProはHero／secondary demoとする。iOSの必須E2Eが安定するまで、Vision Pro固有の作り込みをP0にしない。

## 2. 開発原則

1. iOS ARの固定fixtureでPlace、Pull、Disappearを成立させる
2. 初見の第三者がiPhoneで操作できる
3. 共通Asset／Event／Entitlement modelを固定する
4. Webで実wallet、owner、履歴を取得する
5. 同じ実AssetをiOS ARへ表示する
6. 実transfer後に旧ownerから失効する
7. Physical、redeem、Passportを接続する
8. ユーザー検証、Pitch、提出を完成する
9. 余力がある場合だけVision Pro Hero Demoを更新する

新機能はPrimary E2E、RWA安全性、提出証拠のいずれかを直接改善する場合だけP0にする。

## 3. Client境界

~~~text
Solana devnet / Helius
          ↓
Twinfold API + Core Models
       ↙             ↘
Next.js Web       TwinfoldCore + TwinfoldSpatial (Swift Package)
                       ↓
              apps/ios  (SwiftUI + ARKit Adapter)
                       ↓
                    iPhone

Secondary:
TwinfoldCore + TwinfoldSpatial → apps/visionos (RealityView) → Vision Pro
~~~

### 共通層（Swift Package）

- Asset、Provenance、Entitlementの表示
- Place、Pull、Appear、Disappear
- pending、confirmed、failed
- API clientとMock／Solana provider
- Product event計測

### iOS AR Adapter

- ARKit（ARView、ARWorldTrackingConfiguration）
- camera permissionとAR session
- camera-relative anchor（空中配置）、touch（tap／drag／pinch）
- touch入力、移動、回転、scale
- app lifecycleと端末Build設定

### Vision Pro

- 既存SwiftUI／RealityKit prototypeを同じSwift Packageへ接続する
- 同じfixture／Assetを表示できればHero Demoへ使う
- Hero Demo録画はFinal Buildで余力があれば
- Vision Pro固有機能をiOS共通層へ入れない

## 4. 最初に固定する契約

Web、API、Swift Package（iOS／visionOS）が同じJSONを読み込む。型の実体は [Technical Architecture](./architecture.md) 第4節。

- TwinfoldAsset: id、address、owner、title、display、provenance、physical
- ProvenanceEvent: kind、source、status、transaction、slot、occurredAt
- PhysicalDescriptor: condition、rights、custody、lastVerifiedAt
- Entitlement: wallet、assetId、canDisplay、reason、checkedAt
- RedeemedProvenancePassport: sourceAsset、redeemedAt、lastVerifiedAt、limitations
- Reference Asset: 権利上安全な実物1点
- Test wallets: transfer元・先のdevnet wallet

MockAssetProviderとSolanaAssetProviderは同じ型を返す。fixtureは画面上で DEMO DATA、実接続は DEVNET と表示する。

## 5. 実装フェーズ

フェーズは順番に進める。前のフェーズのDoneを満たすまで次へ進まない。

### Phase 0 — Preflight

目的: 開幕後に設計判断で止まらない状態を作り、事前開発を開示できるbaselineを残す。

- Positioning、P0、Out of Scopeを固定
- 既存Web／visionOSの実装状態を記録
- 開幕前のcommit、screen recording、未実装一覧をbaselineとして保存
- Xcode、iOS deployment target、XcodeGenの構成を固定し、`apps/ios` を生成
- iPhone Development Buildの署名・起動方法を確認
- TestFlightを使うか、対面Development Buildに限定するか決める
- 権利上安全なReference Asset候補を最低1点決める
- collector／supplier interview guideを用意

Done: iPhoneで空のAR sceneが起動し、開幕後に作る範囲と事前コードを説明できる。

### Phase 1 — Testable Mock

目的: iPhoneでTwinfoldのAha momentを体験できるTestable Mockを作る。

1. 公式track、judge、提出項目を再確認
2. Reference Asset fixtureをMy Collectionへ表示
3. tapでカメラ正面の空中にAssetをPlace
4. ドラッグで回転、ピンチでscale
5. Assetから2〜3個のprovenance nodeをPull
6. 疑似transferでpending→confirmed→Disappear
7. resetを実装
8. 第三者2〜5名がiPhoneで試す

Done: 説明なしで Place → Pull → Disappear を完走できる。1分weekly updateを録画する。

### Phase 2 — Solana Connection

目的: fixtureの入力だけをSolana devnetへ差し替える。

1. Web wallet署名認証
2. Metaplex Core Assetのdevnet mint
3. Heliusからowner、metadata、transactionを取得
4. transactionをProvenanceEventへ正規化
5. Web TimelineとMy Collectionへ表示
6. WebからiOSへ短期sessionを渡す
7. iOS appのAssetProviderをSolanaAssetProviderへ接続
8. 実transfer後にEntitlementを再評価
9. 旧ownerからDisappear、新ownerへAppear

Done: WebとiPhoneが同じAsset ID、owner、transactionを表示し、実transferを5分以内に反映する。1分weekly updateを録画する。

### Phase 3 — Startup MVP

目的: 技術デモをreal-world collectiblesのstartup MVPへ変える。

1. Reference AssetをTrust Gateへ登録
2. Physical、condition、rights、custodyを表示
3. Vaulted／Physical Ownershipを選択
4. Redeem申請でAssetをlock／retire
5. Passportへ来歴と非保証範囲を残す
6. collector累計10名、supplier累計3者を目標に検証
7. 英語landing pageとwaitlistを公開
8. supplier／collectorの実証協力intentを得る

Done: 実物登録からredeem／Passportまでをdry runでき、需要検証の最低ラインを満たす。1分weekly updateを録画する。

### Phase 4 — Final Build

- 新機能を追加しない
- iPhone E2Eを3回連続成功させる
- 通信失敗、重複Event、順序逆転、再試行を確認
- Web／iOS AR比較テストを完了
- transferから表示失効までを計測
- PresentationとDemoのstoryを固定
- iOSが安定している場合だけVision Proへ同じAssetを表示

Done: MVP Acceptance Criteriaの必須証拠が揃い、動画だけでも価値と実装を理解できる。

### Phase 5 — Submission

- 本番相当E2Eを5回確認
- clean cloneから再現
- README、architecture、既知の制約を更新
- Presentation videoとProduct Demo videoを撮影
- GitHub、使用chain／tool、Team、GTM、tractionを確認
- 事前開発と開幕後の作業を開示
- link、音声、英語、秘密情報を確認
- 新機能を追加せず、最終link確認後に余裕を持ってsubmit

## 6. 毎日の進め方

1. Primary E2Eを最初から一度実行
2. 最も手前の失敗を当日の最優先Issueにする
3. Issueへ入力、期待結果、確認方法を書く
4. 一つの観測可能な成果まで実装
5. WebとiOSの両方への影響を確認
6. screen recording、transaction、logのいずれかを残す
7. 翌日の最初の一手を一文で記録

## 7. Definition of Done

- fixture／devnetを明示している
- 実機で再現できる
- 同じ操作を繰り返せる
- errorとretryを確認している
- 秘密鍵、個人情報、無許諾画像を含まない
- Primary E2Eでの役割を説明できる
- 制約と証拠をIssueまたはREADMEへ残している

### 証拠ファイルの置き場

画面録画、transaction signature、失効時間のログなどの証拠は、repoに入れずTwinfold共通のGoogle Drive（アカウントはNotionの外部サービス台帳を参照）に置く。

```text
Twinfold/evidence/
  YYYY-MM-DD_<phase>_<内容>.mp4   例: 2026-09-18_phase1_ios-place-pull-disappear.mp4
  YYYY-MM-DD_<phase>_<内容>.md    transaction signature、計測値、環境
```

置いたら共有リンクを該当GitHub Issueのコメントと、Notionスケジュールの該当週に貼る。weekly updateと提出時の「開幕後に完成した作業の開示」はこのフォルダから作る。

## 8. 実機チェック

### iPhone P0

- [ ] iOS AR Buildが実機で起動
- [ ] camera permissionとAR sessionが正常
- [ ] tapで空中配置ができ、ドラッグ回転・ピンチscaleが動く
- [ ] touchで選択、移動、scaleできる
- [ ] provenance textが読める
- [ ] background／foreground復帰後も継続できる
- [ ] owner変更後に表示を失効できる
- [ ] 3回連続でE2E成功

### Vision Pro P1

- [ ] 既存prototypeが実機またはSimulatorで起動
- [ ] iOSと同じAsset IDとownerを表示
- [ ] Pitch用の短いHero recordingを取得

## 9. Blocker時の切り替え

| Blocker | 切り替え |
|---|---|
| TestFlightが間に合わない | 対面Development Buildで検証し、Demo videoを提出 |
| iOS ARのanchor保存が不安定 | session内配置に限定し、再起動後永続化をP1へ移す |
| Solana同期が未完成 | RPC refreshで状態変化を再取得し、制約を明示 |
| Reference Assetの権利未確定 | 権利上安全な別個体（別の絵師・版元の浮世絵、または著作権消滅図案の切手）へ切り替える |
| RWA Layerが間に合わない | Physical情報とredeem stateをfixtureと明示し、虚偽の実運用を示さない |
| Vision Pro対応が不安定 | Hero Demoを外し、iOS ARの完成度へ集中する |
| 複数platformで開発が拡散 | Android、Questを停止し、iOSへ集中する |
