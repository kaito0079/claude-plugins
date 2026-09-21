# Learn From Insights

公式 `/insights` コマンドがセッションごとに生成する分析データ（`~/.claude/usage-data/facets/*.json`）を**横断集計**し、
プロジェクト `CLAUDE.md` / `.claude/notes/` / 個人 memory のいずれにもまだ反映されていない**頻出パターン**を抽出して提案する Claude Skill。

## 使い方

```
/learn-from-insights
```

呼び出すと Claude が：

1. `bash ~/.claude/skills/learn-from-insights/stage-facets.sh` を実行して facets を `/tmp/claude/insights-facets/` にステージング
2. プロジェクト `CLAUDE.md` / `.claude/notes/` / memory の既存内容を読む
3. facets の `friction_detail` をクラスタリング、複数セッションで再出現するパターンを抽出
4. 既存ルールでカバー済みのものは除外
5. 残った候補を **destination 別に分類**（CLAUDE.md / notes / memory / 新規 skill 候補）
6. 単一の統合提案を表示 → ユーザーが承認キー（`P1, P2, U1` 等）で選択
7. 承認分だけ書き込み

## なぜ作ったか

`/insights` は HTML レポートを生成するだけで、**memory やプロジェクトルールへの自動反映はやらない**。
このスキルがその「人間が HTML を読んで判断→ファイルに反映」の一連の流れを半自動化する。

memory（個人）は Claude 標準機能がリアルタイム保存するが、**複数セッションを横断した頻度分析は不在**。
このスキルはそこを補完する。

## 設計メモ

- **遅延ステージング**: スキル呼び出し時に `bash <skill-dir>/stage-facets.sh` が走るだけ。SessionStart hook を追加していないのでセッション開始コストはゼロ。
- 1 回あたり ~200KB の cp（数百セッション分の facets でもこのオーダー）。
- 不要なら `/tmp/claude/insights-facets/` を `rm -rf` するだけ。

## 前提

- 本スキルが `~/.claude/skills/learn-from-insights/` に symlink 済み（配置手順はリポジトリ README 参照）
- 過去に 1 回でも `/insights` を実行済み（`~/.claude/usage-data/facets/` にデータがある）

## 関連

- 公式 `/insights`: 本スキルが入力として使うデータを生成する組み込みコマンド
- `.claude/notes/<topic>.md`（チーム共有の手動編集ディレクトリ）: 本スキルの書き込み先候補のひとつ
- Claude 標準 **memory**: 個人スコープのフィードバックを自動保存する。本スキルがその index (MEMORY.md) を読み、未保存パターンだけを提案する
