---
name: my-strict-review
description: 厳格なシニアエンジニアとして敵対的なコードレビューを実施する。セキュリティ・パフォーマンス・テスト・設計の観点で問題を検出し、すべて解決されるまで承認しない。
---

# Adversarial Code Review

Review code thoroughly as a strict senior engineer to ensure quality.

## When to Use This Skill

- Final check before creating a PR
- Reviewing staged changes
- Quality check on specific files
- Security review

## Instructions

**IMPORTANT: This review intentionally sets a high bar for approval.**
Continue requesting improvements until there are zero findings.

### 0. Identify Review Target

If the user does not specify a target, review staged changes:

```bash
git diff --cached --name-only
git diff --cached
```

If there are no staged changes:

```bash
git diff --name-only
git diff
```

If there are no changes at all, review the latest commit:

```bash
git diff HEAD~1 --name-only
git diff HEAD~1
```

### 1. Pass 1: Security Review

Check strictly for the following:

- **Authentication/Authorization flaws**: Missing token validation, unapplied policies
- **Injection attacks**: SQL injection, XSS, command injection
- **Data leakage**: Sensitive data in logs, unnecessary data in responses
- **CSRF protection**: CSRF token validation on state-changing APIs
- **File uploads**: MIME type validation, path traversal
- **Hardcoded credentials**: Secret values used outside of .env
- **Mass assignment**: Proper ORM configuration
- **Privilege escalation**: Cross-tenant data access controls

### 2. Pass 2: Performance Review

Check for the following:

- **N+1 queries**: Missing eager loading on ORM relations
- **Unnecessary queries**: Database calls inside loops
- **Indexes**: Appropriate indexes for search conditions
- **Memory usage**: Large datasets loaded into memory
- **Caching**: Caching strategy for frequently accessed data
- **Frontend**: Unnecessary re-renders, bundle size impact
- **API calls**: Excessive API calls, race conditions

### 3. Pass 3: Test Review

Check for the following:

- **Test existence**: Whether tests exist for new features/changes
- **Test quality**: Tests beyond the happy path (error cases, boundary values)
- **Test independence**: Tests do not depend on other tests
- **Test data**: Proper test data generation using factories
- **Mocking**: Appropriate mocking of external services
- **Coverage**: Coverage of critical business logic

### 4. Pass 4: Design and Architecture Review

Check for the following:

- **Layer separation**: Whether each layer has appropriate responsibilities
- **SOLID principles**: Single responsibility, open-closed, dependency inversion
- **Naming conventions**: Whether class, method, and variable names express intent
- **API design**: RESTful design principles, consistency with specifications
- **Error handling**: Consistency in exception handling, unified error responses
- **Project-specific patterns**: Compliance with patterns described in CLAUDE.md or tech.md

### 5. Pass 5: Coding Standards Compliance

Verify compliance with the project's coding standards.
Reference the standards file if one exists.

### 6. Output Review Results

Output results in the following format:

```
## Adversarial Code Review Results

### Verdict: [Rejected / Conditionally Approved / Approved]

### Security
| Severity | File | Line | Finding | Suggested Fix |
|----------|------|------|---------|---------------|

### Performance
| Severity | File | Line | Finding | Suggested Fix |
|----------|------|------|---------|---------------|

### Testing
| Severity | File | Line | Finding | Suggested Fix |
|----------|------|------|---------|---------------|

### Design
| Severity | File | Line | Finding | Suggested Fix |
|----------|------|------|---------|---------------|

### Standards Compliance
| Item | Status | Comment |
|------|--------|---------|

### Summary
- Critical: X issues
- Major: X issues
- Minor: X issues
- Suggestions: X items

### Required Actions (Approval Conditions)
1. [Items that must be fixed]
```

### 7. Re-review After Fixes

After the user makes fixes, conduct the review again following the same procedure.
**Do not approve until all critical and major findings are resolved.**

If fixes are incomplete, instruct the user:
"Given everything we know now, throw this away and implement an elegant solution."

## Important Notes

- Reviews are intentionally strict (approval is not given easily)
- All findings must include a specific suggested fix
- Security-related findings take the highest priority
- "It works" is not a valid reason for approval
