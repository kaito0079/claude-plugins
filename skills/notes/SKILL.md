---
name: notes
description: Records learnings and discoveries from the session in the .claude/notes/ directory, managed as a team-wide knowledge base. Organizes entries by topic and updates the README.md index.
---

# Session Notes Recording

Record learnings and discoveries in .claude/notes/, organized by topic, to build a shared team knowledge base.

## When to Use This Skill

- When a significant discovery is made during a session
- When recording the cause and fix for a bug
- When recording architectural decisions
- When recording performance improvement insights
- When summarizing knowledge gained during PR creation

## Instructions

### 1. Review Existing Notes

First, check the current notes structure. Read the files under `.claude/notes/`.
Review the contents of `.claude/notes/README.md` to understand the index.

### 2. Classify the Content

Classify discoveries and learnings into the following categories:

| File | Content |
|------|---------|
| `mistakes-and-fixes.md` | Mistakes, their fixes, and prevention strategies |
| `architecture-decisions.md` | Architectural decisions and their rationale |
| `performance-insights.md` | Performance-related insights |
| `security-notes.md` | Security-related notes |
| `domain-knowledge.md` | Business domain knowledge |
| `dev-environment.md` | Development environment tips and troubleshooting |
| `testing-patterns.md` | Testing patterns and best practices |

If a new category is needed, create the file and add it to README.md.

### 3. Note Entry Format

Append entries within each file using the following format:

```markdown
### [Concise Title]
**Date**: YYYY-MM-DD
**Related PR**: #XXX (if applicable)
**Related Files**: path/to/file.php (if applicable)

[Description of the content]

**Lesson Learned**: [How to handle the same situation in the future]
```

### 4. Update README.md Index

When a new entry is added, update `.claude/notes/README.md`:

- Add new files to the "File List" table if applicable
- Update the "Last Updated" column to today's date
- Add the new entry's title and filename to the "Recent Additions" section

### 5. Reflect in CLAUDE.md (If Significant)

For discoveries that meet the following criteria, consider adding them to CLAUDE.md:

- Important rules that should be referenced in every session
- Prevention strategies for recurring mistakes
- New development patterns or workflows

Confirm with the user before updating CLAUDE.md.

### 6. Session Summary

When invoked at session end, automatically summarize the following:

- Major changes made during this session
- Problems encountered and their solutions
- Patterns and considerations discovered
- Insights applicable to future sessions

## Important Notes

- Organize notes by topic (not chronologically)
- If an existing entry covers the same topic, consolidate or update it
- Never record sensitive information (API keys, passwords, etc.)
- `.claude/notes/` should be committed to git and shared across the team
- Keep entries concise, but detailed enough for your future self to understand
