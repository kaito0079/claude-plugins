# claude-plugins

Claude Code の **公開可能な拡張キット**。スキル / エージェント / ユーティリティスクリプトを
Claude Code のプラグインとして配布する。
マシン固有の hook 本体や `settings.json` は含まない。

## インストール

このリポジトリはプラグインのマーケットプレイス `kaito-plugins` を兼ねる。
マーケットプレイスとして登録し、使うプラグインを入れる。

```bash
claude plugin marketplace add kaito0079/claude-plugins
claude plugin install kaito-review@kaito-plugins
claude plugin install kaito-workflow@kaito-plugins
```

Claude Code の中からは `/plugin marketplace add` と `/plugin install` で同じことができる。
`--scope project` を付けると、プロジェクトの `.claude/settings.json` に登録され、そのプロジェクトで
作業する全員が同じプラグインを使える。

手元の clone を直接読ませる場合は、パスを指定して登録する。編集はセッションの開始時か
`/reload-plugins` で反映される。1 回だけ試すなら `claude --plugin-dir plugins/kaito-review` でもよい。

```bash
claude plugin marketplace add /path/to/claude-plugins
```

## 構成

```
claude-plugins/
├── README.md
├── CLAUDE.md                     プロジェクトルール (Skill/Agent authoring 規約)
├── docs/
│   └── authoring-guide.md        スキル/エージェント作成ガイド
├── .claude-plugin/
│   └── marketplace.json          マーケットプレイス kaito-plugins の定義
└── plugins/
    ├── kaito-review/             レビューと品質
    │   ├── .claude-plugin/plugin.json
    │   ├── skills/
    │   │   ├── code-review/      /code-review - 観点別の並列コードレビュー
    │   │   ├── strict-review/    /strict-review - 敵対的コードレビュー
    │   │   └── techdebt/         /techdebt - 技術的負債検出
    │   └── agents/
    │       ├── strict-review.md  レビューエージェント
    │       └── techdebt.md       技術的負債エージェント
    └── kaito-workflow/           開発の進め方と振り返り
        ├── .claude-plugin/plugin.json
        ├── skills/
        │   ├── team-builder/          /team-builder - チーム並列実装
        │   └── learn-from-insights/   /learn-from-insights - /insights 集計→ルール提案
        └── bin/                       プラグインを入れると PATH に入る
            ├── claude-bash-stats         transcript の Bash 呼び出し集計
            └── claude-merge-transcripts  worktree 分散 transcript をメインリポに集約
```

hook 本体と `settings.json` への hook 登録は本リポに含めない。個人の cmux 環境や worktree
レイアウトに強く依存し、公開キットとして再利用できないため。

## スキル一覧

プラグインのスキルは `/<プラグイン名>:<スキル名>` でも呼べる。ほかに同じ名前のスキルがなければ
`/<スキル名>` だけでよい。プロジェクトに同じ名前のスキルがある場合は、短い名前ではプロジェクトの
スキルが動くので、こちらは名前空間付きで呼ぶ。

| プラグイン | スキル | 呼び出し | タイミング |
|-----------|--------|---------|-----------|
| kaito-review | code-review | `/kaito-review:code-review` | PR またはブランチの変更のレビュー時。観点別サブエージェントを並列起動し、既存コメントの対応状況も判定 |
| kaito-review | strict-review | `/strict-review` | PR作成前。5パスで厳格レビュー |
| kaito-review | techdebt | `/techdebt` | セッション終了時。負債を検出しレポート |
| kaito-workflow | team-builder | `/team-builder` | 設計書やタスクから並列実装チームを構築。ドメイン分割＋レビュー |
| kaito-workflow | learn-from-insights | `/learn-from-insights` | 公式 `/insights` の facets を横断集計し、CLAUDE.md / .claude/notes/ / memory への追加候補を提案 |

`code-review` は Claude Code 同梱のスキルと名前が重なるため、名前空間付きで呼ぶ。

## エージェント一覧

スキルと連携して自律的にタスクを実行するサブエージェント。`subagent_type` には
`kaito-review:<名前>` の形で指定する。

| エージェント | 説明 |
|-------------|------|
| kaito-review:strict-review | 厳格なシニアエンジニアとして敵対的コードレビューを実施 |
| kaito-review:techdebt | コードベースの技術的負債を検出しレポートを生成 |

`team-builder` はレビュー担当に `kaito-review:strict-review` を使う。`kaito-review` を入れていない
場合は `general-purpose` で代用する。

## スキル詳細

### `/kaito-review:code-review` - 観点別の並列コードレビュー

```
/kaito-review:code-review
/kaito-review:code-review 123
```

ロジック / セキュリティ / テスト / 改善提案の 4 観点を並列で起動し、リポジトリに規約文書
（`CLAUDE.md`、`.claude/rules/`、`CONTRIBUTING.md` など）があれば規約準拠の観点も加える。
結果は `[MUST]` / `[IMO]` / `[ASK]` / `[NITS]` / `[LGTM]` のタグ付きで統合して表示する。
PR に未解決のレビュースレッドがあれば、指摘への対応が適切か（未対応 / 対応が不十分 / 説明の再確認が必要 /
対応済み）も判定する。PR がなければ、デフォルトブランチとのローカル差分をレビューする。
エージェント定義は持たず、観点ルールを `references/` からプロンプトとして渡す。PR へのコメント投稿は行わない。

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

### `/learn-from-insights` - /insights 集計→ルール提案

```
/learn-from-insights
```

公式 `/insights` がセッションごとに生成する `~/.claude/usage-data/facets/*.json` を
横断集計し、**まだ `CLAUDE.md` / `.claude/notes/` / memory のどこにも反映されていない
頻出 friction パターン**を抽出して、destination 別の追加候補として提案する。

仕組み:

1. プラグインに同梱の `stage-facets.sh` で facets を
   `/tmp/claude/insights-facets/` にステージング
2. プロジェクト `CLAUDE.md` / `.claude/notes/` / `~/.claude/projects/<dir>/memory/MEMORY.md` の
   既存内容を読んで重複を除外
3. `friction_detail` をクラスタリング → 複数セッションで再出現するもの抽出
4. destination 別に提示（`[P1] CLAUDE.md / [N1] .claude/notes / [U1] memory / [S1] skill候補`）
5. ユーザー承認キーで一括適用

`/insights` 自体は HTML レポート生成までで自動反映はしない。本スキルはその後段を担う。

## ユーティリティスクリプト

`kaito-workflow` の `bin/` にあるコマンドは、プラグインを入れると PATH に入る。

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
