# Project Rules

## Skill & Agent Authoring

When creating or modifying Skills (`SKILL.md`) or Agents (`agents/*.md`), you **MUST** follow the guidelines in [`docs/authoring-guide.md`](docs/authoring-guide.md).

### Language Rules

⬛ MUST
- `SKILL.md` — Japanese or English (pick one and stay consistent within a file)
- `agents/*.md` — Japanese or English (frontmatter + system prompt, consistent within a file)
- `references/*.md` — Japanese or English
- Script comments and docstrings — English (technical artifacts shared with non-Japanese readers)

◆ SHOULD
- Error messages — English, or English + Japanese bilingual

⬛ MUST
- `skills/*/README.md` — Create a Japanese user-facing explanation alongside every `SKILL.md`

○ NICE TO HAVE
- `README.md` (project root, user-facing) — Japanese is OK

### Writing Style

⬛ MUST
- Use grammatically correct, complete sentences (in whichever language the file is written in)
- Structure content with clear sections, headings, bullet points, and tables
- Include a specific suggested action for every finding or recommendation

◆ SHOULD
- Keep instructions imperative and concise (e.g., "Check for N+1 queries" not "You should check for N+1 queries")
- Use consistent terminology throughout a single file

### Priority Notation

When expressing priority levels in Skills or Agents, use the MoSCoW + shape pattern:

```
⬛ MUST - Critical requirement
◆ SHOULD - Strongly recommended
○ NICE TO HAVE - Optional enhancement
```

Do NOT use color-only emoji (🔴🟡🟢) or symbols without text labels.

### Pre-Commit Checklist

Before finalizing any new or modified Skill/Agent, verify:

- [ ] `SKILL.md` / Agent `.md` uses Japanese or English consistently (no mid-file language mixing)
- [ ] Body text uses grammatically correct, complete sentences
- [ ] Content is well-structured (clear headings, sections, lists)
- [ ] Priority levels use MoSCoW + shape notation (if applicable)
- [ ] `skills/*/README.md` exists with Japanese user-facing explanation

## README Maintenance

README.md must stay in sync with the following source files:

| Source | README sections affected |
|--------|------------------------|
| `skills/*/SKILL.md` | スキル一覧テーブル・スキル詳細・構成図 |
| `agents/*.md` | エージェント一覧テーブル・構成図 |
| `scripts/*` | ユーティリティスクリプトセクション |
| `status-line.sh` | ステータスラインセクション |

⬛ MUST
- When adding, removing, or changing the `description` of a skill or agent, update README.md accordingly
- README.md is written in Japanese
