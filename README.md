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
│   ├── strict-review/SKILL.md         /strict-review - 敵対的コードレビュー
│   ├── techdebt/SKILL.md              /techdebt - 技術的負債検出
│   ├── team-builder/SKILL.md          /team-builder - チーム並列実装
│   └── learn-from-insights/SKILL.md   /learn-from-insights - /insights 集計→ルール提案
├── agents/
│   ├── strict-review.md    レビューエージェント
│   └── techdebt.md         技術的負債エージェント
└── scripts/                (→ ~/.local/bin/)
    ├── claude-bash-stats.py        transcript の Bash 呼び出し集計
    └── claude-merge-transcripts.py worktree 分散 transcript をメインリポに集約
```

hook 本体と `settings.json` への hook 登録は本リポに含めない。個人の cmux 環境や worktree
レイアウトに強く依存し、公開キットとして再利用できないため。

## スキル一覧

| スキル | 呼び出し | タイミング |
|--------|---------|-----------|
| strict-review | `/strict-review` | PR作成前。5パスで厳格レビュー（標準 `/review` を上書きしないようリネーム） |
| techdebt | `/techdebt` | セッション終了時。負債を検出しレポート |
| team-builder | `/team-builder` | 設計書やタスクから並列実装チームを構築。ドメイン分割＋レビュー |
| learn-from-insights | `/learn-from-insights` | 公式 `/insights` の facets を横断集計し、CLAUDE.md / .claude/notes/ / memory への追加候補を提案 |

## エージェント一覧

スキルと連携して自律的にタスクを実行するサブエージェント。

| エージェント | 説明 |
|-------------|------|
| strict-review | 厳格なシニアエンジニアとして敵対的コードレビューを実施 |
| techdebt | コードベースの技術的負債を検出しレポートを生成 |

## スキル詳細

### `/strict-review` - 敵対的レビュー

```
/strict-review
/strict-review path/to/file.php
```

5パス: セキュリティ → パフォーマンス → テスト → 設計 → 標準準拠
致命的・重要な指摘が全て解決されるまで承認しない。

### `/techdebt` - 技術的負債検出

```
/techdebt
```

重複コード、コードスメル、未使用コード、TODO/FIXME を検出し優先度別レポート。

### `/team-builder` - チーム並列実装

```
/team-builder
```

設計書やタスクリストに基づきエージェントチームを構築し、並列実装とコードレビューを実施。

1. タスク分析・分割（技術ドメイン / 独立性 / ファイル所有権）
2. チーム構成決定（リーダー + 実装担当 × N + レビュワー）
3. タスク登録・依存関係設定
4. 実装エージェント並列起動
5. 進捗管理 → 全実装完了後にレビュワー起動
6. レビュー指摘をリーダーが修正 → クリーンアップ

モデル戦略: adaptive（推奨）/ deep / fast / budget から選択可能。

### `/learn-from-insights` - /insights 集計→ルール提案

```
/learn-from-insights
```

公式 `/insights` がセッションごとに生成する `~/.claude/usage-data/facets/*.json` を
横断集計し、**まだ `CLAUDE.md` / `.claude/notes/` / memory のどこにも反映されていない
頻出 friction パターン**を抽出して、destination 別の追加候補として提案する。

仕組み:

1. `bash ~/.claude/skills/learn-from-insights/stage-facets.sh` で facets を
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

コンテキスト使用量、バーンレート、ETA などをリアルタイム表示するカスタムステータスライン。

### 表示内容

| 項目 | 説明 |
|------|------|
| モデル名 | 使用中のモデル |
| コンテキスト | 使用量/上限 + プログレスバー + ゾーン表示 |
| In/Out | 入力/出力トークン数 |
| 残りトークン | コンテキスト残量 |
| ETA | 残り使用可能時間の推定 |
| 圧縮回数 | セッション内のコンテキスト圧縮検出回数 |
| バーンレート | トークン消費速度 (tokens/min) |
| Daily/Weekly/Monthly | 累積トークン使用量 |

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
