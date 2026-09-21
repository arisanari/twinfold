---
name: colosseum-catchup
description: Crypto World's Fair 2026（Colosseum）の最新情報（公式blog、worldsfairページ、FAQ、ニュース、X、Discordアナウンス）を前回以降の差分だけ拾い、Twinfoldへの影響（なし／要確認／戦略変更候補）を付けてNotionの「最新情報ログ」へ追記する。毎朝のroutine、または「キャッチアップして」と言われたときに使う。
context: fork
agent: general-purpose
model: sonnet
allowed-tools: WebSearch, WebFetch, Read
---

# Colosseum Catchup

Twinfold（Solana × iPhone AR × 壁に掛ける浮世絵・版画のRWA、拡張は棚〈郷土玩具・こけし〉、提出は2026-10-12）のために、Colosseum関連の新着だけを拾う。戦略は変えない。影響の判定と一次情報のリンクを残すだけ。

## 読む先

### 公開ソース（毎回）

1. https://blog.colosseum.com/ の一覧。前回以降の記事だけ開く
2. https://colosseum.com/worldsfair と https://colosseum.com/hackathon?year=fall2026 。track、judge、賞、提出項目、締切の変更が無いか
3. WebSearch: `Colosseum "Crypto World's Fair"`、`Colosseum hackathon` を直近7日で。Solana Compass、CryptoBriefing、The Block 等のニュースも対象
4. https://colosseum.com/arena/hackathon/hall-of-fame （読めれば）

### ログイン必要（Chromeが使えるときだけ）

本体セッションが Claude in Chrome を使える場合のみ、本体が次を読んで結果をこのskillの出力に足す。forkされたこのskill自身はChromeを持たないので、Chromeが要る部分は「未取得」と書いて本体に返す。

- X: `https://x.com/search?q=from%3AColosseumOrg&f=live` と `https://x.com/ColosseumOrg`
- Discord アナウンス: https://discord.com/channels/1273743461601902789/1417618269522624624

## 前回との差分

- Notionの「最新情報ログ」ページ（AGENTS.md 第2節にURL）の最終エントリの日付を本体から受け取る。受け取れなければ「直近7日」を対象にする。
- 既にログにある項目は再掲しない。

## 出力の形（日本語、そのままNotionに追記できる形）

```markdown
### YYYY-MM-DD

| 影響 | 項目 | 要点 | 出典 |
|---|---|---|---|
| 戦略変更候補 | … | 何が変わったか一行 | URL |
| 要確認 | … | … | URL |
| なし | … | … | URL |

未取得: X（Chrome未接続）、Discord（同上）
```

- 影響の基準: **戦略変更候補** = track、judge、締切、提出項目、審査観点の変更、または壁に掛ける浮世絵・版画（拡張の棚: こけし・郷土玩具）／RWA／AR分野に直接関わる発表。**要確認** = 関連しそうだが読み込みが必要。**なし** = 記録だけ。
- 新着が無い日は `### YYYY-MM-DD` と「新着なし（確認先: blog、worldsfair、FAQ、検索）」の一行だけ。
- 推測で埋めない。読めなかったソースは「未取得」と明記する。
- 結果はテキストで返す。Notionへの書き込みは本体（またはroutine）が行う。
