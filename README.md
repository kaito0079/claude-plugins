# claude-tools

Claude Code のカスタムスキル、エージェント、ステータスライン。
`install.sh` で symlink を張り、全プロジェクトから利用可能。

## インストール

```bash
cd ~/private/claude-tools
chmod +x install.sh
./install.sh
```

## アンインストール

```bash
./install.sh --uninstall
```

## 構成

```
claude-tools/
├── install.sh              symlink 作成/削除
├── status-line.sh          ステータスライン (→ ~/.claude/statusline.sh)
├── CLAUDE.md               プロジェクトルール
├── README.md
├── docs/
│   └── authoring-guide.md  スキル/エージェント作成ガイド
├── skills/
│   ├── plan/SKILL.md       /plan   - 80/20 計画モード
│   ├── review/SKILL.md     /review - 敵対的コードレビュー
│   ├── techdebt/SKILL.md   /techdebt - 技術的負債検出
│   ├── notes/SKILL.md      /notes  - ナレッジベース更新
│   └── team-builder/SKILL.md  /team-builder - チーム並列実装
├── agents/
│   ├── review.md           レビューエージェント
│   └── techdebt.md         技術的負債エージェント
└── scripts/                CLI 横断ユーティリティ (→ ~/.local/bin/)
    └── claude-bash-stats.py  transcript の Bash 呼び出し集計
```

## スキル一覧

| スキル | 呼び出し | タイミング |
|--------|---------|-----------|
| plan | `/plan` | 実装開始前。設計ドキュメント承認後に実装 |
| review | `/review` | PR作成前。5パスで厳格レビュー |
| techdebt | `/techdebt` | セッション終了時。負債を検出しレポート |
| notes | `/notes` | 発見があった時。.claude/notes/ に記録 |
| team-builder | `/team-builder` | 設計書やタスクから並列実装チームを構築。ドメイン分割＋レビュー |

## エージェント一覧

スキルと連携して自律的にタスクを実行するサブエージェント。

| エージェント | 説明 |
|-------------|------|
| review | 厳格なシニアエンジニアとして敵対的コードレビューを実施 |
| techdebt | コードベースの技術的負債を検出しレポートを生成 |

## スキル詳細

### `/plan` - 計画モード

```
/plan ユーザー削除機能を追加したい
```

1. 問題分析 → 2. アプローチ検討（2案以上）→ 3. 設計ドキュメント → 4. 承認待ち → 5. 実装

### `/review` - 敵対的レビュー

```
/review
/review path/to/file.php
```

5パス: セキュリティ → パフォーマンス → テスト → 設計 → 標準準拠
致命的・重要な指摘が全て解決されるまで承認しない。

### `/techdebt` - 技術的負債検出

```
/techdebt
```

重複コード、コードスメル、未使用コード、TODO/FIXME を検出し優先度別レポート。

### `/notes` - ナレッジベース更新

```
/notes N+1クエリの問題を修正したので記録して
/notes 今日の学びをまとめて
```

`.claude/notes/` にトピック別に記録。README.md のインデックスも更新。

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

## ユーティリティスクリプト

`scripts/` 以下の実行可能ファイルは `install.sh` で `~/.local/bin/` にシンボリックリンクされる（拡張子は除去）。

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

`install.sh` で自動的にシンボリックリンクが作成される。
`~/.claude/settings.json` に以下の設定が必要:

```json
{
  "statusLine": {
    "type": "command",
    "command": "cat | bash ~/.claude/statusline.sh"
  }
}
```

## 学習する AI

Claude がミスをしたら:

```
このミスを二度としないように、CLAUDE.md を更新して
```

繰り返すことでプロジェクト固有のルールが蓄積される。
