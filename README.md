# claude-tools

Claude Code のカスタムスキルと worktree マネージャー。
`install.sh` で symlink を張り、全プロジェクトから利用可能。

## インストール

```bash
cd ~/private/claude-tools
chmod +x install.sh
./install.sh
echo 'source ~/.claude-worktrees.sh' >> ~/.zshrc
source ~/.zshrc
```

## アンインストール

```bash
./install.sh --uninstall
```

## 構成

```
claude-tools/
├── install.sh              symlink 作成/削除
├── claude-worktrees.sh     worktree マネージャー (→ ~/.claude-worktrees.sh)
├── README.md
└── skills/
    ├── plan/SKILL.md       /plan   - 80/20 計画モード
    ├── review/SKILL.md     /review - 敵対的コードレビュー
    ├── techdebt/SKILL.md   /techdebt - 技術的負債検出
    └── notes/SKILL.md      /notes  - ナレッジベース更新
```

## スキル一覧

| スキル | 呼び出し | タイミング |
|--------|---------|-----------|
| plan | `/plan` | 実装開始前。設計ドキュメント承認後に実装 |
| review | `/review` | PR作成前。5パスで厳格レビュー |
| techdebt | `/techdebt` | セッション終了時。負債を検出しレポート |
| notes | `/notes` | 発見があった時。.claude/notes/ に記録 |

## Worktree マネージャー

### プロジェクトごとの初回セットアップ

```bash
cd /path/to/project
claude-worktree init        # worktree 作成 (project-a, project-b, project-c)
claude-worktree register    # zuse に登録
```

### 日常の使い方

```bash
zuse              # 登録済みプロジェクト一覧
zuse my-project   # プロジェクト切り替え

za / zb / zc      # worktree A/B/C に移動
z0                # プロジェクトルートに戻る

zswitch a feature/123  # worktree A のブランチ切り替え
zinfo                  # 状態表示

cdev / crev / cana     # 各 worktree で Claude Code 起動
```

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

## 学習する AI

Claude がミスをしたら:

```
このミスを二度としないように、CLAUDE.md を更新して
```

繰り返すことでプロジェクト固有のルールが蓄積される。
