---
name: commit-helper
description: Use when creating Git commits. Triggered by "commit", "make a commit", etc. Infers commit style from existing git log, creates messages with WHY (intent) in the body.
---

# Commit Helper

Creates commits following the project's existing conventions by analyzing recent commit history.

## Commit Flow

### 1. Check Changes and Project Style
```bash
git status                    # List changed files
git diff --staged             # Staged changes
git diff                      # Unstaged changes
git log --oneline -20         # Recent commits (for style inference)
```

### 2. Infer Commit Style

Detect the project's commit style and language from `git log` output.
When inferring, ignore merge commits (`Merge pull request...`, `Merge branch...`) and bot commits.

**Style patterns**:
| Pattern | Style | Example |
|---------|-------|---------|
| `feat:` `fix:` etc. | Conventional Commits | `feat: add user auth` |
| `[PROJ-123]` | Jira integration | `[PROJ-123] add user auth` |
| `#123` | GitHub Issue | `#123 add user auth` |
| `scope:` | Scope prefix | `auth: add login`  |
| No prefix | Simple | `Add user authentication` |

**Language**: Match the language used in existing commits (English, Japanese, etc.)

**Style selection**:
- New directory/module addition → prefer `feat:` or general style over scope prefix
- Changes within existing scope → use `scope:` prefix if project uses it

Create commit messages matching the detected style and language.

### 3. Write Commit Message

**Principles**:
- Title = WHAT (what was done)
- Body = WHY (why it was done) + background, motivation, benefits
- Write enough context for reviewers to understand
- Use bullet points for multiple changes
- Infer WHY from: user's request, conversation context, and git diff analysis
- If WHY is unclear from context, ask user with `AskUserQuestion` before committing

**Good vs Bad Examples**:
```
# Bad - Just repeats WHAT, no WHY
fix: add null check

Added null check.

# Good - WHY is clear
fix: add null check

Users accessing the profile page while logged out
caused a crash on user.name reference.
Redirect to login page instead.
```

**Format** (MUST include all parts):
```
<title (following project style)>

<description - explain the intent (WHY)>

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 4. Execute Commit
```bash
git add <files>  # Stage if needed

git commit -m "$(cat <<'EOF'
Title here

Explain the intent here.
Describe background and benefits.

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 5. Push
Only run `git push` when explicitly requested by user.

## Commit Splitting Guidelines

When committing multiple changes:

- **Add before delete**: During migrations, add new things first, then remove old ones (avoid broken intermediate states)
- **Group related changes**: Same context = one commit
  - Example: New feature + its tests
  - Example: Refactor + related doc updates
- **Respect dependencies**: If A references B, commit B first

## Notes

- **WIP or debug code detected**: Use `AskUserQuestion` to confirm whether to proceed or abort
- **Better WHY**: For richer commit messages, include background/motivation when requesting a commit
