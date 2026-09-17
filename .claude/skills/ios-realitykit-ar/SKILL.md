---
name: ios-realitykit-ar
description: TwinfoldのP0 Spatial ClientであるiPhone AR（SwiftUI + RealityKit + ARKit）と、visionOSと共有するSwift Package（TwinfoldCore／TwinfoldSpatial）の構成、境界、build・simulator・実機の確認手順、実機チェックリスト。apps/ios、packages/TwinfoldCore、apps/visionosのSpatial実装、xcodebuild確認、iPhone実機テストに使う。
---

# iOS RealityKit AR

P0はiPhone AR。Vision Pro（`apps/visionos`）は同じSwift Packageを使うP1のHero Demo。Unity、Quest、AndroidはMVP後で、このskillの対象外。

## 環境（2026-09-18時点で確認済み）

| 項目 | 値 | 備考 |
|---|---|---|
| Xcode | 26.0.1 | iOS 26 SDK。simulator runtime は iOS 18.4／26.0／26.1、visionOS 2.4 |
| iOS deployment target | 17.0 | RealityKit 2 + ARKit `ARView`。実機は arisaiPhone（iPhone 13 Pro 相当、UDID は `xcrun devicectl list devices`） |
| visionOS deployment target | 2.0 | 既存 `apps/visionos/project.yml` |
| プロジェクト生成 | XcodeGen（`project.yml`） | `*.xcodeproj` は生成物。ignore する |
| Swift | 6.0 | strict concurrency で詰まる場合は target 単位で 5 モードへ落とし、理由を残す |
| 配布 | 個人 Team の Development Build（対面） | TestFlight は Apple Developer Program 登録が前提で未決定 |

## 構成

```text
packages/TwinfoldCore/
  Package.swift
  Sources/TwinfoldCore/       共通モデル（Codable）、AssetProvider protocol、MockAssetProvider、Resources/fixtures/demo
  Sources/TwinfoldSpatial/    RealityKit Entity 生成（AssetCard、ProvenanceNode、PlacementState の見た目）。ARKit／UIKit／SwiftUI を import しない
apps/ios/
  project.yml                 target TwinfoldAR、bundle id design.twinfold.ar、local package 依存
  TwinfoldAR/
    CollectionView.swift      My Collection、DEMO DATA バッジ
    ARContainerView.swift     UIViewRepresentable で ARView。平面検出、tap raycast、Anchor
    ARSceneController.swift   Place／Pull／Reset／疑似 transfer の状態
    AROverlayView.swift       ラベル、ボタン、状態表示
apps/visionos/                既存 SwiftUI + RealityKit。TwinfoldCore／TwinfoldSpatial へ接続する
```

- `TwinfoldCore` は Web の `apps/web/lib/contract.ts` の写し。JSON キー名と `CodingKeys` を 1 対 1 にする。手順は `core-contract` skill。
- `TwinfoldSpatial` は platform 非依存。ARKit（平面検出、raycast、session）は `apps/ios/TwinfoldAR/AR*.swift` だけが触る。visionOS 側は `RealityView` で同じ Entity を置く。
- View と Controller は `AssetProvider` protocol だけに依存する。Solana、Helius、HTTP の詳細は将来の `ApiAssetProvider` に閉じる。
- 購入、秘密鍵、配送先入力は iOS／visionOS に置かない。Web の担当。
- 画面には Provider の `isDemoData` に応じて `DEMO DATA` か `DEVNET` を常時表示する。

## Phase 1（Testable Mock）で作るもの

1. My Collection に fixture の切手 1 点
2. AR 画面で水平面を検出し、tap で Place（`AnchorEntity(world:)`）
3. カード tap で provenance ノード 3 件を時系列に引き出す（Pull）
4. 疑似 transfer: pending（半透明）→ confirmed → Disappear。failed は配置を維持して再試行導線
5. Reset
6. simulator では ARKit が動かないので、`ARWorldTrackingConfiguration.isSupported` が false のときは固定位置配置のフォールバックと案内文

Anchor の永続化（再起動後の復元）は P1。session 内だけでよい。

## 確認コマンド

```bash
# 共通 package（macOS ホストでコンパイル。ARKit を package に入れないこと）
cd packages/TwinfoldCore && swift build

# iOS app（simulator、署名なし）
cd apps/ios && xcodegen generate
xcodebuild -project apps/ios/TwinfoldAR.xcodeproj -scheme TwinfoldAR \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO

# visionOS app
cd apps/visionos && xcodegen generate
xcodebuild -project apps/visionos/TwinfoldVision.xcodeproj -scheme TwinfoldVision \
  -destination 'generic/platform=visionOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

simulator での UI 確認は本体セッションが iOS Simulator ツールで行える。AR の平面検出は実機のみ。

## 実機（iPhone）

1. iPhone を Mac に接続し、`xcrun devicectl list devices` で `available` になることを確認
2. Xcode で `apps/ios/TwinfoldAR.xcodeproj` を開き、Signing & Capabilities で個人 Team を選ぶ
3. 実機を選んで Run。初回はデバイス側で開発者を信頼する
4. 合格条件は build-order 第 8 節の iPhone P0 チェック

`xcodebuild -destination 'id=<UDID>'` でも build できるが、署名設定が要るので初回は Xcode GUI が早い。実機確認はユーザーの作業。implementer は「何を tap して何が見えれば合格か」を一行ずつ渡す。

## よくある詰まり

- `ARView.raycast(from:allowing:alignment:)` は `.estimatedPlane` から始め、平面が安定したら `.existingPlaneGeometry` に切り替えると誤配置が減る。
- `MeshResource.generateText` は重い。ノード数は最小にし、文字列を短くする。
- Swift 6 の strict concurrency で `ARView` や `Entity` の扱いに `@MainActor` が要る。Controller を `@MainActor @Observable` にする。
- `UIRequiredDeviceCapabilities: arkit` を付けると simulator build には影響しないが、App Store 配布時に非 AR 端末を弾く。Development Build では問題ない。
- `Bundle.module` は package の `resources:` を宣言していないと存在しない。
