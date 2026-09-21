---
name: core-contract
description: TwinfoldAsset／ProvenanceEvent／Entitlement等の共通モデルと、fixture（DEMO DATA）をWeb TypeScriptとSwift Package（iOS・visionOS共有）で同時に整合させる手順。共通モデルの追加・変更、fixtureの差し替え、Provider境界の実装、クライアント間で型がずれていないかの確認に使う。
---

# Core Contract

共通モデルの形と不変条件は `docs/architecture.md` 第4〜5節が定義する。このskillはそれをコードとfixtureへ落とす手順を定める。

## 正本の置き場

| 種類 | 場所 | 役割 |
|---|---|---|
| 型の正本 | `apps/web/lib/contract.ts` | `TwinfoldAsset`、`ProvenanceEvent`、`ProvenanceKind`、`DisplayDescriptor`、`PhysicalDescriptor`、`Entitlement`、`RedeemedProvenancePassport`、`AssetProvider` interface |
| fixtureの正本 | `fixtures/demo/assets.json`、`fixtures/demo/wallets.json` | 浮世絵Reference Asset 1点（DEMO DATA、主役、額装カード表現）＋こけしReference Asset 1点（棚の拡張例、USDZ表現）の2点構成と、transfer元・先のtest wallet |
| Swiftの写し | `packages/TwinfoldCore/Sources/TwinfoldCore/Models/*.swift` | `Codable` の写し。`CodingKeys` はJSONのkey名と1対1。iOSとvisionOSが共有 |
| Webのfixture | `apps/web/lib/fixtures/demo/` | `scripts/sync-fixtures.sh` のコピー先。静的import |
| Swiftのfixture | `packages/TwinfoldCore/Sources/TwinfoldCore/Resources/fixtures/demo/` | 同スクリプトのコピー先。`Bundle.module` から読む |

写しを手で書き換えない。契約を変えたら、この順で全部を変える。

## 型の不変条件

- `id` はTwinfold内部の安定ID（例: `tf-ukiyoe-001`）。`address` はSolana上の外部識別子。fixtureでは `address` を `DEMO-...` で始める。
- `network` はMVPでは `"devnet"` 固定。
- `ProvenanceEvent.source` は `"onchain" | "offchain_evidence" | "twinfold_interpretation"` の3値。UIで混同しない。
- `ProvenanceEvent.status` は `"pending" | "confirmed" | "failed"`。fixtureは `confirmed` を基本にし、pending／failedは操作で作る。
- `ProvenanceKind` はMVP必須の `minted | transferred | rwa_verified | vaulted | redeemed` だけを実装する。Post-MVPの種類を先に増やさない。
- `Entitlement.canDisplay` の判定条件（session、chain owner一致、active、display rights、frozen／redeemed／exception除外）を弱めない。
- fixtureに実walletの秘密情報、配送先、個人名、権利未確認の画像パスを入れない。画像は `apps/web/public/artworks/` の自作SVGか、権利上安全な浮世絵・こけしの画像だけを使う。
- 日時はISO 8601（UTC）。金額は持たない（MVPでは購入を実装しない）。
- Swift側のenumは `String` raw valueで、未知の値はdecode失敗にせず `unknown` へ落とすか、失敗を明示的にログする。黙って読み飛ばさない。

## 変更手順

1. `docs/architecture.md` 第4節と矛盾しないことを確認する。矛盾するなら先に文書を直す提案をする。
2. `apps/web/lib/contract.ts` を変える。
3. `fixtures/demo/*.json` を変える。全clientが同じ `id`、`owner`、`provenance` を読むこと。
4. Swiftの写しを変える。`CodingKeys` をJSONのkey名と一致させ、optionalはJSONの `?` と一致させる。
5. `scripts/sync-fixtures.sh` を実行して配布する。
6. 検証: Web `npm run build`、Package `cd packages/TwinfoldCore && swift build`、iOS／visionOS の `xcodebuild`（手順は `ios-realitykit-ar`）。
7. UIの表示ラベルが `DEMO DATA` のままになっているか確認する。

## Providerの境界

```ts
interface AssetProvider {
  readonly isDemoData: boolean;
  getAssets(wallet: string): Promise<TwinfoldAsset[]>;
  getAsset(assetId: string): Promise<TwinfoldAsset>;
  refreshOwnership(assetId: string): Promise<Entitlement>;
}
```

```swift
protocol AssetProvider {
  var isDemoData: Bool { get }
  func getAssets(wallet: String) async throws -> [TwinfoldAsset]
  func getAsset(assetId: String) async throws -> TwinfoldAsset
  func refreshOwnership(assetId: String) async throws -> Entitlement
}
```

- `MockAssetProvider` は fixture を読む。`SolanaAssetProvider`（Web）と `ApiAssetProvider`（Swift）はBackend API経由でHelius／RPCの結果を同じ型で返す。
- UI（React component、SwiftUI View、RealityKit Entity生成）はProviderのinterfaceだけに依存する。RPC、DAS、Heliusのimportをそこに置かない。
- `isDemoData` に応じて画面の `DEMO DATA`／`DEVNET` を切り替える。

## 報告に含めること

- 変更した型とfield、影響したclient
- fixtureの件数とID一覧
- 実行した検証と結果
- まだ写しが揃っていないclient
