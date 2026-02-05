# Commit Helper

Gitコミット作成を支援するClaude Skillです。
プロジェクトの既存コミット履歴からスタイルを推測し、WHY（意図）を含むコミットメッセージを作成します。

## 何ができるか

- 既存コミット履歴からスタイル・言語を自動推測
- Conventional Commits / Jira / GitHub Issue連携 等に対応
- WHAT（何をしたか）とWHY（なぜしたか）を明確に分けたメッセージ作成
- 複数変更時の適切なコミット分割

## こんな時に使える

- コミットメッセージの書き方に迷った時
- プロジェクトの慣習に合わせたコミットを作りたい時
- レビュアーに意図が伝わるコミットメッセージを書きたい時

## 使い方

### 1. コミットを依頼

```
コミットして
```

```
変更をコミット
```

```
commit the changes
```

### 2. 自動でスタイル推測

`git log` から以下を検出：

| パターン | スタイル |
|----------|----------|
| `feat:` `fix:` 等 | Conventional Commits |
| `[PROJ-123]` | Jira連携 |
| `#123` | GitHub Issue連携 |
| prefix無し | シンプル |

言語（日本語/英語等）も既存コミットに合わせます。

### 3. コミットメッセージ作成

```
fix: add null check

Users accessing the profile page while logged out
caused a crash on user.name reference.
Redirect to login page instead.

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## コミットメッセージの原則

| 要素 | 内容 |
|------|------|
| タイトル | WHAT（何をしたか） |
| 本文 | WHY（なぜしたか）+ 背景・動機・効果 |

### 悪い例

```
fix: add null check

Added null check.
```
→ WHATを繰り返しているだけ

### 良い例

```
fix: add null check

Users accessing the profile page while logged out
caused a crash on user.name reference.
Redirect to login page instead.
```
→ なぜその修正が必要だったかが明確

## ファイル構成

```
commit-helper/
├── SKILL.md     # Claude向け指示書
└── README.md    # このファイル
```

## 前提条件

- Gitリポジトリであること
- コミット履歴があること（スタイル推測のため）
