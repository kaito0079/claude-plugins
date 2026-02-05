# Project Rules

## Skill & Agent Authoring

When creating or modifying Skills (`SKILL.md`) or Agents (`agents/*.md`), you **MUST** follow the guidelines in [`docs/authoring-guide.md`](docs/authoring-guide.md).

### Language Rules

⬛ MUST
- `SKILL.md` — Write in English
- `agents/*.md` — Write in English (frontmatter + system prompt)
- `references/*.md` — Write in English
- Script comments and docstrings — Write in English

◆ SHOULD
- Error messages — English, or English + Japanese bilingual

○ NICE TO HAVE
- `README.md` (user-facing) — Japanese is OK

### Writing Style

⬛ MUST
- Use grammatically correct, complete English sentences
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

- [ ] `SKILL.md` / Agent `.md` is written entirely in English
- [ ] YAML frontmatter `description` is in English
- [ ] Body text uses grammatically correct, complete sentences
- [ ] Content is well-structured (clear headings, sections, lists)
- [ ] Priority levels use MoSCoW + shape notation (if applicable)
- [ ] No Japanese remains in the file (except annotated domain-specific terms)
