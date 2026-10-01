---
name: my-team-builder
description: 設計書やタスクリストを元に、並列実装とレビュー用のエージェントチームを構築する。技術ドメインで作業を分割し、依存関係を管理し、品質保証を調整する。
---

# Team-Based Parallel Implementation

Build agent teams from design documents or task lists. Coordinate parallel implementation with code review to balance quality and efficiency.

Running-state visibility (Running / Needs input pills, OS notifications) is
handled automatically by the cmux Claude wrapper — this skill does not touch
sidebar state.

## When to Use This Skill

Use `/my-team-builder` only when **all** of the following hold:

⬛ MUST — Activation checklist (all four must be YES)

- [ ] Three or more **independent** tasks within a single feature/PR scope
- [ ] Each task edits a **distinct set of files** (no shared edit targets)
- [ ] Parallel execution actually shortens wall-clock time (not heavily sequential)
- [ ] Each task fits in 1-3 files (granularity small enough for one agent)

Typical trigger phrases from the user:

- 「この設計書に沿って実装して」 (multi-file design)
- 「フロントとバックを同時に直して」 (cross-domain)
- 「N 個のサービスを並行リファクタしたい」
- 「セキュリティ / パフォーマンス / テスト観点でそれぞれレビューして」

## When NOT to Use This Skill

⬛ MUST — Skip my-team-builder in these cases

- 1-2 tasks where parallelization adds no value
- Single-domain small changes (a quick bug fix)
- Research-only or investigation-only tasks
- **Heavily sequential work**: when most tasks have `blockedBy` dependencies, a single session is more efficient
- **Multiple agents must edit the same file**: later writes silently overwrite earlier changes (data loss, not a Git conflict)
- **Cost-sensitive contexts**: teams consume several times more tokens than a single session

### `/my-team-builder` vs. opening a new cmux window

Some users (including the author of this skill) keep one cmux window per task. The two patterns serve different needs:

| Open a new cmux window | Invoke `/my-team-builder` |
|------------------------|------------------------|
| Independent features or feature branches | Single feature/PR with multiple deliverables |
| Each task needs deep, interactive user dialogue | Specs are clear enough to fan out |
| Long-running exploration | Predictable implementation work |
| Different repos / cwds | Same repo, same branch |

Default to the cmux-window pattern; reach for `/my-team-builder` only when the activation checklist passes.

## How It Works

```
1. Activation check          → checklist + key phrases
2. Dry-run plan presentation → user approves before any agent is spawned
3. TeamCreate + TaskCreate + dependencies
4. Parallel implementation agents (one tool call, multiple Task invocations)
5. Reviewer (after all implementation tasks complete)
6. Leader applies review fixes
7. Cleanup (shutdown_request + TeamDelete)
```

For role-by-role visibility, open each task in a separate cmux window instead
of invoking `/my-team-builder`.

## Instructions

### 1. Analyze and Split Tasks

Apply the splitting criteria below:

| Criterion | Description |
|-----------|-------------|
| **Technical domain** | Split by language or layer (Python / TypeScript / Go / CSS). Minimize context switches |
| **Independence** | Identify tasks with no dependencies to maximize parallelism |
| **Granularity** | Target 1-3 files per agent. Too many files reduces accuracy |
| **File ownership** | Assign each file to exactly one agent. Never let multiple agents edit the same file |

#### File Conflict Prevention

⬛ MUST — **Never allow parallel edits to the same file.** A later write silently overwrites earlier changes.

Countermeasures:

- Define file ownership at split time
- If the same file must change in multiple tasks, serialize them with `blockedBy`
- As a last resort, have the leader integrate changes afterward

#### Dependency Graph

```
Independent tasks (parallel)
  Task A ─┐
  Task B ─┼──→ Dependent task (after prerequisites complete)
  Task C ─┘         │
                     └──→ Review task (after all implementation completes)
```

### 2. Present a Dry-Run Plan and Wait for Approval

⬛ MUST — Do not call `TeamCreate` or any `Task` tool until the user explicitly approves the plan.

Output the plan in this exact format, then ask "この計画で進めて良いですか？":

```markdown
## my-team-builder plan

### Tasks
| # | role        | subject              | files                        |
|---|-------------|----------------------|------------------------------|
| 1 | backend-dev | API endpoint for X   | src/api/x.ts, src/api/x.test.ts |
| 2 | frontend-dev| UI for X             | src/ui/X.tsx, src/ui/X.css   |
| 3 | infra-dev   | Terraform for X      | infra/x.tf                   |
| R | reviewer    | Full review          | (read-only)                  |

### File ownership
- backend-dev:  src/api/**
- frontend-dev: src/ui/**
- infra-dev:    infra/**

### Dependencies
- 1, 2, 3 run in parallel
- Reviewer waits for 1, 2, 3

### Model strategy: adaptive
- Leader:    opus
- Implementers: sonnet
- Reviewer:  opus

### Estimated cost class: medium
(single session ≈ low / 3 sonnet implementers + opus reviewer ≈ medium)
```

When the user approves, proceed. If they reject, refine and re-present.

### 3. Determine Team Composition

| Role | subagent_type | Responsibility | mode |
|------|---------------|----------------|------|
| **Leader** | (self) | Task management, dependency control, applying review fixes | — |
| **Implementer × N** | `general-purpose` | Implementation per technical domain | `bypassPermissions` |
| **Reviewer** | `my-strict-review` | Quality verification of all deliverables | default |

#### Model Strategy

| Strategy | Leader | Implementers | Reviewer | Use case |
|----------|--------|-------------|----------|----------|
| **adaptive** (recommended) | opus | sonnet | opus | Typical development. Good cost-quality balance |
| **deep** | opus | opus | opus | Complex design, security-critical implementation |
| **fast** | sonnet | sonnet | sonnet | Speed-first, routine implementation |
| **budget** | sonnet | haiku | sonnet | Cost minimization, simple tasks |

Set via the `model` parameter on the Task tool.

#### Implementer Splitting Templates

| Pattern | Agent A | Agent B | Agent C |
|---------|---------|---------|---------|
| Full-stack feature | Backend API | Frontend UI | Infrastructure |
| API + DB | Migrations + Models | Controllers + Tests | Config + Middleware |
| Microservices | Service A | Service B | Shared libraries |

### 4. Create Team and Register Tasks

```
TeamCreate
  team_name: "<feature-name>"
  description: "<purpose>"
```

For each task, call `TaskCreate` with:

- **subject**: Concise task name (imperative form)
- **description**: Detailed specification (file paths, schemas, signatures, reference patterns from existing code)
- **activeForm**: Display text while in progress (present continuous)

For dependencies, use `TaskUpdate` with `addBlockedBy`:

- Independent tasks: no blockers
- Dependent tasks: specify prerequisite task IDs
- Reviewer task: blocked by all implementation task IDs

### 5. Launch Implementation Agents

⬛ MUST — Launch all independent-task agents in a **single message** (one Task tool call per agent, all in parallel).

#### Prompt Design

Agents run in isolated sessions with no shared context. Include all necessary information:

```
1. Role name and team name
2. Assigned task IDs
3. Per-task detailed specs (file paths, code examples, constraints)
4. Reference patterns from existing code (file paths + relevant snippets)
5. Explicit file ownership (what the agent may and may not edit)
6. Post-completion steps: TaskUpdate to completed → TaskList for next task
```

#### Prompt Template

```
You are "<role-name>", a teammate on the "<team-name>" team.
Your job is to implement the following tasks:

## Your assigned tasks
- Task #N: <subject>
- Task #M: <subject>

## Task #N: <subject>

**Create/modify file:** `<file-path>`

**Requirements:**
- <detailed spec>

**Reference patterns:**
Read these files first:
- `<existing-file-path>` — <what to look for>

**IMPORTANT:**
- Read existing files before modifying
- Follow existing code style and conventions exactly
- Only edit files assigned to you (do NOT modify files owned by other teammates)
- Mark tasks as completed via TaskUpdate when done
- Check TaskList after completing tasks

Start with Task #N, then Task #M.
```

#### Launch Parameters

```
Task tool:
  subagent_type: "general-purpose"
  name: "<role-name>"
  team_name: "<team-name>"
  mode: "bypassPermissions"
  model: "sonnet"          # adaptive strategy
  run_in_background: true
```

### 6. Manage Progress

For each agent completion notification:

1. Verify deliverables with the `Read` tool
2. `TaskList` to check overall progress

When all implementation tasks complete, send `shutdown_request` to implementation agents and proceed to step 7.

### 7. Conduct Review

#### Launch the Reviewer

```
Task tool:
  subagent_type: "my-strict-review"
  name: "reviewer"
  team_name: "<team-name>"
```

Reviewer prompt must include:

- List of files to review
- Design document requirements (review criteria)
- Review perspectives (design alignment, security, pattern consistency, error handling)

#### Handle Review Findings

⬛ MUST — **The leader applies review fixes directly.** Reasons:

- Most fixes span multiple files
- Re-launching implementation agents adds unnecessary overhead
- The leader holds full context

Fix priority:

1. **Critical** → Fix immediately
2. **Major** → Fix unless intentional by design (document the rationale)
3. **Minor** → Recommended fix. Address with comments or small changes
4. **Informational** → Record only; consider in future phases

### 8. Cleanup

⬛ MUST — Always run cleanup, even on partial failure.

- Send `shutdown_request` to all remaining agents
- Run `TeamDelete` to remove team resources

## Anti-Patterns

### No 3-Layer Nesting

Do not spawn subagents inside teammates (Leader → Teammate → Subagent). This is inefficient:

- Token cost inflates across 3 layers
- Direct messaging with the leader is lost
- Management overhead increases

**Fix**: Design task granularity appropriately and keep the hierarchy to 2 layers (Leader → Teammate).

### No Parallel Edits to the Same File

When multiple agents edit the same file, the later write silently overwrites the earlier one. This is **data loss**, not a Git conflict.

**Fix**: Define file ownership at task-definition time.

### Avoid Over-Detection

Auto-detecting domains or team composition is less reliable than using pre-designed templates.

**Fix**: Prefer template-based composition (see Examples below) and confirm via the dry-run plan.

### Do Not Skip the Dry-Run Plan

Launching TeamCreate before the user approves the plan wastes tokens on a team they may reject. **Always present the plan first.**

## Important Notes

- **Context sufficiency is paramount**: Agents run in isolated sessions. Quality degrades when the prompt lacks file paths, code examples, or existing patterns
- **Investigate existing patterns first**: Before launching the team, use Explore agents or Glob/Grep/Read to understand existing conventions
- **3-4 agents is optimal**: Too many increases coordination cost; too few reduces parallelism benefit
- **Launch the reviewer after implementation**: Reviewing mid-implementation only increases churn
- **The leader handles fixes**: Re-launching agents for review fixes is inefficient

## Examples

### Pattern 1: Full-Stack Feature (Backend + Frontend + Infrastructure)

```
Model strategy: adaptive (Leader=opus, Implementers=sonnet, Reviewer=opus)

Team composition:
  backend-dev (sonnet)  → API controllers, models, migrations
  frontend-dev (sonnet) → Pages, components, API hooks
  infra-dev (sonnet)    → IaC definitions, IAM policies, environment config
  reviewer (opus)       → Full review (launched after implementation completes)

File ownership:
  backend-dev:  src/api/**, db/migrations/**
  frontend-dev: src/frontend/pages/**, src/frontend/components/**
  infra-dev:    infra/**, config/**
```

### Pattern 2: API + Database Feature

```
Model strategy: adaptive

Team composition:
  schema-dev (sonnet)   → Database migrations, model definitions, seed data
  api-dev (sonnet)      → Controllers, use cases, request/response schemas
  test-dev (sonnet)     → Integration tests, unit tests, test fixtures
  reviewer (opus)       → Full review

File ownership:
  schema-dev: db/**, src/models/**
  api-dev:    src/controllers/**, src/usecases/**, src/schemas/**
  test-dev:   tests/**
```

### Pattern 3: Codebase Refactoring

```
Model strategy: fast (all sonnet — routine work)

Team composition:
  refactor-a (sonnet) → Service A file group
  refactor-b (sonnet) → Service B file group
  reviewer (sonnet)   → Full review

File ownership:
  refactor-a: services/service-a/**
  refactor-b: services/service-b/**
```

### Pattern 4: Parallel Review / Investigation

```
Model strategy: deep (all opus — analysis depth matters)

Team composition:
  security-reviewer (opus)    → Security-focused review
  performance-reviewer (opus) → Performance-focused review
  test-reviewer (opus)        → Test coverage review
```
