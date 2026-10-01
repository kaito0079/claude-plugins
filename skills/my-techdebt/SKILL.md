---
name: my-techdebt
description: コードベースの技術的負債を検出してレポートを生成する。コードの重複、コードスメル、未使用 import、過度に複雑な関数を特定する。
---

# Technical Debt Detection and Reporting

Scan the codebase to identify technical debt and generate a report with improvement suggestions.

## When to Use This Skill

- Quality check at the end of a session
- Code quality verification before creating a PR
- Periodic technical debt inventory
- Identifying refactoring targets

## Instructions

Follow these steps to detect technical debt and generate a report:

### 1. Identify Scan Target

First, check the files changed during the current session:

```bash
git diff --name-only HEAD~5
git diff --name-only --cached
```

If there are no changes, ask the user to specify the target directory.

### 2. Detect Code Duplication

Search for similar patterns within the same module as the changed files:

- Repeated logic (3 or more occurrences)
- Code blocks suspected of being copy-pasted
- Validation or data transformation logic that could be consolidated

### 3. Identify Code Smells

Analyze code from the following perspectives:

**Backend:**
- Methods exceeding 100 lines
- Nesting deeper than 4 levels
- Methods with 5 or more parameters
- God Objects (classes with too many responsibilities)
- Potential N+1 queries
- Improper exception handling (empty catch blocks, etc.)

**Frontend:**
- Components exceeding 200 lines
- Components with too many props (7 or more)
- useEffect dependency array issues
- Potential unnecessary re-renders
- Usage of `any` type

### 4. Detect Unused Code

- Unused import statements
- Unused variables and functions
- Dead code (unreachable code blocks)
- Tally of TODO/FIXME comments

### 5. Security-Related Checks

- Hardcoded credentials or secrets
- Potential SQL injection
- Potential XSS
- Improper authorization checks

### 6. Generate Report

Output the analysis results in the following format:

```
## Technical Debt Report
Date: YYYY-MM-DD
Target: [Scanned files/directories]

### High Priority (Immediate action recommended)
- [Security risks or potential critical bugs]

### Medium Priority (Address in next sprint)
- [Code smells, design issues]

### Low Priority (Address during refactoring)
- [Style improvements, minor duplication]

### Statistics
- Files scanned: X
- TODO/FIXME count: X
- Duplicate code blocks: X
- High-complexity functions: X

### Improvement Suggestions
1. [Specific improvement suggestion with target file]
```

## Important Notes

- Scanning is read-only; do not modify any files
- Display the report to standard output (confirm with the user before saving to a file)
- For large-scale scans, recommend narrowing the target scope as it may take time
