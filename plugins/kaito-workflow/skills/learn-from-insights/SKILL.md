---
name: learn-from-insights
description: Claude Code 標準の `/insights` がセッションごとに出力する facets を全履歴横断で集計し、繰り返し現れる friction パターンをクラスタリングして、プロジェクト `CLAUDE.md` / `.claude/notes/` / ユーザーメモリへの追加候補を提案する。
---

# Learn From Insights

`/insights` already analyzes each session with Haiku and writes structured per-session
analysis to `~/.claude/usage-data/facets/*.json` (fields like `friction_counts`,
`friction_detail`, `outcome`, `goal_categories`, `underlying_goal`).

This skill aggregates **across** those per-session facets to find patterns that
appear in multiple sessions but are not yet captured in:

- Project `CLAUDE.md` (team-shared rules)
- Project `.claude/notes/*` (team-shared knowledge base)
- User memory at `~/.claude/projects/<encoded-cwd>/memory/` (personal preferences/feedback)
- Existing skills under `~/.claude/skills/`

It then proposes additions to whichever destination fits each pattern.

## Prerequisites

⬛ MUST
- `/insights` has been run at least once so `~/.claude/usage-data/facets/` has data
- The `kaito-workflow` plugin is installed (the staging script ships inside it)

## Staging

Facets data is **lazily staged** to `/tmp/claude/insights-facets/` on each invocation
via `bash <skill-dir>/stage-facets.sh`. All subsequent reads in this skill target the
staged copy, not the original location. This keeps session startup cost zero — the copy
happens only when the skill is actually invoked.

## Instructions

### 1. Stage facets

Run the staging script bundled with the plugin:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/learn-from-insights/stage-facets.sh"
```

If the script exits non-zero, surface the error to the user and stop. The most common
case is that `/insights` has never been run — tell the user to run `/insights` first.

### 2. Load existing rules

Read what is already captured so the proposal can skip duplicates. Read these in order:

| Target | Path |
|---|---|
| Project rules | `<cwd>/CLAUDE.md` |
| Project notes | `<cwd>/.claude/notes/*.md` (if any) |
| User memory index | `~/.claude/projects/<encoded-current-cwd>/memory/MEMORY.md` (if accessible; sandbox may deny — that's OK, skip silently) |
| User-global rules | `~/.claude/CLAUDE.md` (if exists) |

For memory: read MEMORY.md to know the existing slug list; do **not** attempt to read
every memory file. The index is enough to detect "already covered".

### 3. Aggregate facets

Read every file in `/tmp/claude/insights-facets/*.json`. Each file shape:

```json
{
  "underlying_goal": "...",
  "goal_categories": {"...": 1},
  "outcome": "fully_achieved | mostly_achieved | partially_achieved | not_achieved",
  "user_satisfaction_counts": {"likely_satisfied": 1},
  "claude_helpfulness": "very_helpful | helpful | neutral | not_helpful",
  "session_type": "...",
  "friction_counts": {"wrong_approach": 1, ...},
  "friction_detail": "concrete description of friction (may be empty)",
  "primary_success": "...",
  "brief_summary": "...",
  "session_id": "..."
}
```

Focus on the `friction_detail` strings — that is where recurring user instructions and
Claude's repeated mistakes surface in natural language.

### 4. Cluster friction patterns

Group `friction_detail` strings into clusters by semantic similarity. Be liberal with
paraphrase matching. For each cluster compute:

- `sessions`: number of distinct sessions the cluster appears in
- `friction_kinds`: union of `friction_counts` keys across the cluster
  (e.g., `wrong_approach`, `excessive_changes`, `misunderstood_request`)

⬛ MUST: process all `friction_detail` data, not just the top hits. Even rare clusters
can be high-signal if the friction kind is `user_rejected_action` or `excessive_changes`.

### 5. Match against existing rules

For each cluster, ask:

- Is this pattern already in `CLAUDE.md` (project or user-global)?
- Is it already in `.claude/notes/*`?
- Is there a memory slug whose description covers it (per `MEMORY.md` index)?

If yes, **drop the cluster**. The goal is to surface only gaps.

### 6. Classify destination per remaining cluster

| Pattern type | Suggested destination |
|---|---|
| Team-shared rule (e.g., "don't appeal to industry standards; cite specific code") | Project `CLAUDE.md` |
| Team-shared knowledge (e.g., "the X test runner needs Y env var") | Project `.claude/notes/<topic>.md` |
| Personal preference / Claude-facing instruction (e.g., "user prefers terse responses") | User memory (`~/.claude/projects/<encoded-cwd>/memory/feedback_*.md`) |
| Repeated Claude mistake pattern that needs a one-shot automation | Suggest a new skill or hook (do not auto-create — flag it) |

For ambiguous cases, default to **project `.claude/notes/`** (easier to revise than CLAUDE.md).

### 7. Present a single consolidated proposal

Show one block and stop for input. Never write before approval. Format (Japanese is fine
for user-facing output):

```
=== /learn-from-insights 提案 ===
集計対象: N セッション ( /tmp/claude/insights-facets/*.json )
既存ルールと突き合わせて未カバーのもののみ表示

# Project rules — CLAUDE.md 追記候補
[P1] 根拠を「業界水準」で済ませず、コード/ドキュメントの具体的箇所を示す
     evidence: 3 sessions, friction=wrong_approach,user_rejected_action
     destination: <cwd>/CLAUDE.md (新規 "Reasoning" セクション)

[P2] 過剰な防御策（SHA pin、try/except 乱用）を勝手に追加しない
     evidence: 4 sessions, friction=excessive_changes
     destination: <cwd>/CLAUDE.md (Coding rules)

# Project notes — .claude/notes/ 追記候補
[N1] sandbox 制限下では ~/.claude/projects 配下が読めない
     evidence: 4 sessions, friction=sandbox_permission_blocks
     destination: <cwd>/.claude/notes/dev-environment.md

# User memory — 個人スコープ feedback 追記候補
[U1] ユーザーはアプローチを急がず最初に制約確認を求める
     evidence: 5 sessions, friction=misunderstood_request,wrong_approach
     destination: ~/.claude/projects/<encoded-cwd>/memory/feedback_<slug>.md

# Skill/Hook candidate — 自動化提案（未実装）
[S1] PR の commit message 整形パターンが頻出 → /commit-helper 風 skill 候補
     evidence: 6 sessions
     destination: (人間判断、自動作成しない)

承認キーを返答してください。例: "P1, P2, N1, U1" / "all-P" / "none"
```

### 8. Apply approved items

Write only the approved keys.

⬛ MUST
- For project `CLAUDE.md` / `.claude/notes/*`: write directly (sandbox allows `$WORK_DIR`)
- Before any project file write, show the diff to the user
- Preserve existing structure (don't reorder sections; only append)
- For `.claude/notes/`: also update `<cwd>/.claude/notes/README.md` index if it exists

⬛ MUST for memory items
- When direct write to the memory dir succeeds, write the proposed `.md` file there and append the index line to `MEMORY.md`.
- When direct write fails (typically because the current project does not allow writes outside `$WORK_DIR`), fall back to staging: write the proposed files to `/tmp/claude/insights-memory-stage/<encoded-current-cwd>/`, plus a `_INDEX-APPEND.md` listing the lines to append to `MEMORY.md`. Tell the user the path and that a sync step (Stop hook, or a manual `mv`) will move them. The cwd encoding rule is `path.replace("/", "-").replace(".", "-")`.

⬛ MUST for skill/hook candidates
- Do not create files for these. Just describe the candidate. The user decides if/how to build it.

### 9. Cleanup (optional)

After applying, optionally invoke:

```bash
rm -rf /tmp/claude/insights-facets
```

Leaving the staging dir is also fine — `stage-facets.sh` overwrites on next run.

## Out of Scope

- Re-running `/insights` itself — that is the built-in command's job. This skill consumes its output.
- Live transcript scanning — facets are the input format; transcripts are not read here.
- Auto-creating skills or hooks — only proposed in the report, never built automatically.
- Editing other people's memory or another user's `~/.claude/` files.

## Failure Modes

| Cause | Symptom | Handling |
|---|---|---|
| `/insights` has never been run | `stage-facets.sh` exits 2 with "facets dir does not exist" | Tell user to run `/insights` first, exit |
| `/insights` produced 0 facets | exit 3 with "no facet files" | Same as above |
| All clusters already covered | "No new patterns to surface" | Print and exit cleanly |
