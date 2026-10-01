# claude-tools

Claude Code の **公開可能な拡張キット**: スキル / エージェント / ユーティリティスクリプト / ステータスライン。
`~/.claude/` 配下に symlink して使う。マシン固有の hook 本体や `settings.json` は含まない。

## インストール

インストーラは持たない。任意の場所に clone し、以下 4 種類の symlink を張れば動く。

```bash
CLAUDE_TOOLS="$(pwd)"   # このリポの clone 先

# スキル / エージェント
mkdir -p ~/.claude/skills ~/.claude/agents
ln -fns "$CLAUDE_TOOLS"/skills/* ~/.claude/skills/
ln -fns "$CLAUDE_TOOLS"/agents/* ~/.claude/agents/

# ユーティリティスクリプト (拡張子を除いたコマンド名で配置)
mkdir -p ~/.local/bin
for f in "$CLAUDE_TOOLS"/scripts/*.py; do
  ln -fns "$f" ~/.local/bin/"$(basename "${f%.*}")"
done

# ステータスライン (settings.json 側の設定は「ステータスライン」セクション参照)
ln -fns "$CLAUDE_TOOLS"/status-line.sh ~/.claude/statusline.sh
```

設定管理リポジトリなどから自動化する場合も、張るリンクはこの 4 種類だけ。

## 構成

```
claude-tools/
├── README.md
├── CLAUDE.md              プロジェクトルール (Skill/Agent authoring 規約)
├── status-line.sh         ステータスライン (→ ~/.claude/statusline.sh)
├── docs/
│   └── authoring-guide.md スキル/エージェント作成ガイド
├── skills/
│   ├── my-strict-review/SKILL.md         /my-strict-review - 敵対的コードレビュー
│   ├── my-techdebt/SKILL.md              /my-techdebt - 技術的負債検出
│   ├── my-team-builder/SKILL.md          /my-team-builder - チーム並列実装
│   └── my-learn-from-insights/SKILL.md   /my-learn-from-insights - /insights 集計→ルール提案
├── agents/
│   ├── my-strict-review.md    レビューエージェント
│   └── my-techdebt.md         技術的負債エージェント
└── scripts/                (→ ~/.local/bin/)
    ├── claude-bash-stats.py        transcript の Bash 呼び出し集計
    └── claude-merge-transcripts.py worktree 分散 transcript をメインリポに集約
```

hook 本体と `settings.json` への hook 登録は本リポに含めない。個人の cmux 環境や worktree
レイアウトに強く依存し、公開キットとして再利用できないため。

## スキル一覧

| スキル | 呼び出し | タイミング |
|--------|---------|-----------|
| my-strict-review | `/my-strict-review` | PR作成前。5パスで厳格レビュー（標準 `/review` を上書きしないようリネーム） |
| my-techdebt | `/my-techdebt` | セッション終了時。負債を検出しレポート |
| my-team-builder | `/my-team-builder` | 設計書やタスクから並列実装チームを構築。ドメイン分割＋レビュー |
| my-learn-from-insights | `/my-learn-from-insights` | 公式 `/insights` の facets を横断集計し、CLAUDE.md / .claude/notes/ / memory への追加候補を提案 |

## エージェント一覧

スキルと連携して自律的にタスクを実行するサブエージェント。

| エージェント | 説明 |
|-------------|------|
| my-strict-review | 厳格なシニアエンジニアとして敵対的コードレビューを実施 |
| my-techdebt | コードベースの技術的負債を検出しレポートを生成 |

## スキル詳細

### `/my-strict-review` - 敵対的レビュー

```
/my-strict-review
/my-strict-review path/to/file.php
```

5パス: セキュリティ → パフォーマンス → テスト → 設計 → 標準準拠
致命的・重要な指摘が全て解決されるまで承認しない。

### `/my-techdebt` - 技術的負債検出

```
/my-techdebt
```

重複コード、コードスメル、未使用コード、TODO/FIXME を検出し優先度別レポート。

### `/my-team-builder` - チーム並列実装

```
/my-team-builder
```

設計書やタスクリストに基づきエージェントチームを構築し、並列実装とコードレビューを実施。

1. **発動条件チェック**（独立 3+ タスク / ファイル分離 / 並列で短縮可能）
2. **ドライランプラン提示** → ユーザー承認（必須）
3. チーム構成決定（リーダー + 実装担当 × N + レビュワー）
4. タスク登録・依存関係設定
5. 実装エージェント並列起動
6. 全実装完了 → レビュワー起動
7. レビュー指摘をリーダーが修正
8. クリーンアップ（agents + Team）

モデル戦略: adaptive（推奨）/ deep / fast / budget から選択可能。

cmux 環境では `Running` / `Needs input` ピルは cmux Claude wrapper が自動表示する（本スキルはサイドバーを触らない）。

### `/my-learn-from-insights` - /insights 集計→ルール提案

```
/my-learn-from-insights
```

公式 `/insights` がセッションごとに生成する `~/.claude/usage-data/facets/*.json` を
横断集計し、**まだ `CLAUDE.md` / `.claude/notes/` / memory のどこにも反映されていない
頻出 friction パターン**を抽出して、destination 別の追加候補として提案する。

仕組み:

1. `bash ~/.claude/skills/my-learn-from-insights/stage-facets.sh` で facets を
   `/tmp/claude/insights-facets/` にステージング
2. プロジェクト `CLAUDE.md` / `.claude/notes/` / `~/.claude/projects/<dir>/memory/MEMORY.md` の
   既存内容を読んで重複を除外
3. `friction_detail` をクラスタリング → 複数セッションで再出現するもの抽出
4. destination 別に提示（`[P1] CLAUDE.md / [N1] .claude/notes / [U1] memory / [S1] skill候補`）
5. ユーザー承認キーで一括適用

`/insights` 自体は HTML レポート生成までで自動反映はしない。本スキルはその後段を担う。

## ユーティリティスクリプト

`scripts/` 以下の実行可能ファイルは `~/.local/bin/` に拡張子を除いた名前で symlink して使う。

### `claude-bash-stats`

Claude Code の transcript (`~/.claude/projects/*/*.jsonl`) を横断スキャンし、Bash ツール呼び出しの頻度を集計する。worktree を多用するとプロジェクトディレクトリが分散するため、プロジェクト名フィルタで複数 worktree をまとめて集計できる。

```bash
# 全プロジェクト
claude-bash-stats

# 特定リポジトリだけ (worktree 横断)
claude-bash-stats -f <repo-name>

# settings.json の allow リスト貼り付け用
claude-bash-stats -f <repo-name> --format rules
```

`~/.claude/settings.json` の allow ルールと突き合わせ、未登録のコマンドだけを表示する（`--include-allowed` で全件）。allow リスト整備の判断材料に使う想定。

### `claude-merge-transcripts`

worktree 配下に分散した transcript jsonl を、メインワークツリーの project dir に一括コピーする
**バックフィルツール**。Stop hook などで新規セッション分を自動同期している場合は、初回 1 回または
新しい worktree を大量に作った後の手動メンテで使う想定。

```bash
# まず dry-run でコピー対象を確認
claude-merge-transcripts -f <repo-name> --dry-run

# 実際に集約
claude-merge-transcripts -f <repo-name>

# auto-detect が効かない場合はメインの cwd を明示
claude-merge-transcripts -f <repo-name> --target-cwd /Users/me/work/<repo-name>
```

メイン worktree は内部で `git worktree list --porcelain` の最初のエントリから
自動判定する。既にコピー済み（mtime ベース）のファイルはスキップするので、
重ね打ちしても無害。

## ステータスライン

レート制限 (5 時間 / 週) の消費状況を常時表示する 2 行構成のステータスライン。

```
📁 claude-tools (🌿 main) │ 🤖 Opus 5
⏳5h ▓▓▓░░░░░░░ 30% │ 📅週 ▓▓░░░░░░░░ 23%
```

### 表示内容

| 項目 | 説明 |
|------|------|
| 📁 / 🌿 | カレントディレクトリ名と git ブランチ |
| 🤖 | 使用中のモデル |
| ⏳5h / 📅週 | レート制限の使用率 (常時表示) |
| 🧠 | コンテキスト使用率。`THRESHOLD` (既定 80) 以上のときだけ 2 行目に追加 |

レート制限のバーは、`resets_at` から逆算したウィンドウ経過率と使用率を比較して色を変える。
単純な使用率の閾値ではなく「ペース」で判断するため、ウィンドウ序盤の高使用率を警告できる。

| 色 | 条件 | 意味 |
|----|------|------|
| 緑 | 使用率 ≤ 経過率 | 期待ペース内。まだ余裕がある |
| 黄 | 使用率 > 経過率 | ペース超過。このままだとリセット前に枯渇する |
| 赤 | 使用率 > 経過率 かつ `RATE_RED_THRESHOLD` (既定 80) 以上 | ペース超過かつ残りわずか |

`resets_at` が取得できない場合はペース判定ができないため無色で表示する。

### セットアップ

`status-line.sh` を `~/.claude/statusline.sh` に symlink した上で、`settings.json` に以下を入れる:

```json
{
  "statusLine": {
    "type": "command",
    "command": "cat | bash ~/.claude/statusline.sh"
  }
}
```
