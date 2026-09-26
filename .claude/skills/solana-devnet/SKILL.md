---
name: solana-devnet
description: Metaplex Core（umi、@metaplex-foundation/mpl-core）でのdevnet mint／transfer、Helius DAS（getAsset、getAssetsByOwner、getSignaturesForAsset）での取得、transactionをProvenanceEventへ正規化する規則、test walletの扱い。scripts/solanaでのmint、SolanaAssetProvider（Web）の実装、Phase 2 Solana Connectionの作業に使う。
---

# Solana Devnet

Phase 2（Solana Connection）でfixtureの入力をSolana devnetへ差し替えるときの実装知識。型の正本は `docs/architecture.md` 第4〜6節、`apps/web/lib/contract.ts`。fixtureとの整合は `core-contract` skillに従う。

## 全体像

```text
scripts/solana（Operator用CLI）
  → Metaplex Core Assetをdevnetへmint／transfer
  → metadata JSONをdevnetで無料のuploaderへ保存

Helius DAS（サーバー側のみ）
  → getAsset / getAssetsByOwner / getSignaturesForAsset
  → apps/web の server API route（app/api/...）だけが呼ぶ

SolanaAssetProvider（apps/web/lib/providers/）
  → server API routeを叩き、TwinfoldAsset／ProvenanceEventへ正規化
  → MockAssetProviderと同じ型を返す。UIはisDemoDataでDEMO DATA／DEVNETを切替
```

UI（React component、SwiftUI View、RealityKit Entity）からHelius／RPCを直接importしない。`AssetProvider` interfaceだけに依存する（`core-contract` skill参照）。

## mint／transfer（scripts/solana）

- 場所: `scripts/solana/`。`apps/web` とは別の `package.json`（依存を混ぜない）
- 依存: `@metaplex-foundation/umi`、`umi-bundle-defaults`、`umi-uploader-irys`、`umi-web3js-adapters`、`@metaplex-foundation/mpl-core`、`@solana/web3.js`
- metadataのホスティング: Irysのdevnetエンドポイント（`https://devnet.irys.xyz`）。小さいJSONペイロードはdevnetで無料。自前サーバー不要で、mpl-coreの`create`はURIさえあればよいためこれを選んだ。mainnetのIrys/Arweaveアップロードは有料なので混同しない
- 入力: `scripts/solana/inputs/<assetId>.json`（`name`、`description`、`attributes`。絵師・題名・版元・年代・実寸・状態所見・evidence hashを想定。未確認の項目は`"未確認"`のまま許容し、確認済みであるかのように書かない）
- `--dry-run`: metadata JSONを組み立てて表示するだけで、アップロードもtransactionも送らない
- devnet以外のRPC URLを設定すると実行を拒否する（`assertDevnet`）。mainnetへは絶対に接続しない
- test walletの秘密鍵は repoの外（既定 `~/.config/twinfold/devnet/owner-a.json`、`owner-b.json`）に置き、`TWINFOLD_DEVNET_KEY_DIR`／`TWINFOLD_OWNER_A_KEYPAIR`／`TWINFOLD_OWNER_B_KEYPAIR` で差し替える。stdout・logに秘密鍵やseedを出さない。公開鍵、transaction signature、Asset addressだけを出す
- airdropはdevnetのみ。devnet faucetは1日の上限やレート制限があるため、失敗時は https://faucet.solana.com を案内するだけで再試行を無限に繰り返さない

## Helius DAS取得

- `getAsset(assetId)`: Asset本体、owner、on-chain metadata URIを取得
- `getAssetsByOwner(wallet)`: walletが保有するAsset一覧
- `getSignaturesForAsset(assetId)` / transaction履歴: mint、transferをtransaction signature単位で取得
- サーバー側（`app/api/...` route handler）だけが `HELIUS_API_KEY` を読む。`NEXT_PUBLIC_` prefixを付けない（AGENTS.md第3節）。UIやclient componentからHeliusを直接呼ばない
- Asset addressは環境変数か設定ファイルで差し替え可能にする。fixtureのmintが先行し、本物のReference AssetはRWA登録完了後に別途mintされるため、コードにハードコードしない

## ProvenanceEventへの正規化規則

| 入力 | 正規化 |
|---|---|
| Metaplex Core `create` transaction | `kind: "minted"`, `source: "onchain"` |
| owner変更transaction | `kind: "transferred"`, `source: "onchain"` |
| off-chain metadata（RWA Admin登録、Trust Gate通過） | `kind: "rwa_verified"`, `source: "offchain_evidence"` |
| Twinfold側の保管判断（Vaulted Ownership選択など） | `source: "twinfold_interpretation"` |

- `status`: transactionを送信した直後は`pending`。RPC／DASで確定を確認できたら`confirmed`。送信失敗またはtimeoutで`failed`。investigateし続けて確定しないものを`pending`のまま放置しない
- 冪等化: `transaction`（signature）または明示的な`requestId`をキーにして同じeventを二重生成しない。再処理しても同じ最終状態になることを確認する
- `slot`、`evidenceHash`は取得できた場合だけ埋める。推測で埋めない
- `metadata`フieldにはUIが解釈に使う最小限だけを入れ、個人情報や非公開契約内容を入れない

## test walletの扱い

- 2つの役割: owner-a（初期owner）、owner-b（transfer先）。fixtureの `DEMOwalletA...`／`DEMOwalletB...` とは別物（fixtureは devnet Assetを持たない仮名義）
- 生成は `scripts/solana` の wallet生成スクリプトで行い、鍵ファイルは repo外に置く
- devnet SOLのairdropだけを行う。実SOL、mainnet walletとは何があっても混同しない

## 守る規則（AGENTS.md第3節・第5節の再掲）

- UIからSolana RPC／DASを直接呼ばない。必ず`AssetProvider`経由にする
- `HELIUS_API_KEY`を`NEXT_PUBLIC_`にしない。サーバー側env（`.env.local`）だけで読む
- devnet transferを売上と呼ばない。MVPの`buy`は本番決済を意味しない
- onchain fact（`source: "onchain"`）、off-chain evidence（`"offchain_evidence"`）、Twinfold interpretation（`"twinfold_interpretation"`）をUIで混同しない。まとめて「確認済み」と表示しない
- mainnetのエンドポイントへは接続しない。コード内でdevnet以外を拒否するguardを外さない
- 秘密鍵、APIキー、配送先などの個人情報をrepo・log・動画に入れない

## 確認方法

```bash
cd scripts/solana && npm install
npm run wallets:generate            # devnet keypair生成 + airdrop（repo外に保存）
npm run mint -- --input=inputs/pipeline-test.json --dry-run
npm run mint -- --input=inputs/pipeline-test.json   # 実際にdevnetへmint

cd apps/web && npm run build && npm run lint
```

`HELIUS_API_KEY`が`apps/web/.env.local`に無い場合、SolanaAssetProviderの実接続部分は「blocked: HELIUS_API_KEY未設定」として報告し、コードとbuildまでは進める。
