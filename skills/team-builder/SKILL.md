---
name: team-builder
description: 設計書やタスクリストを元に、並列実装とレビュー用のエージェントチームを構築する。技術ドメインで作業を分割し、依存関係を管理し、品質保証を調整する。
---

# Team-Based Parallel Implementation

Build agent teams from design documents or task lists. Coordinate parallel implementation with code review to balance quality and efficiency.

## When to Use This Skill

- Implementing multiple files based on a design document
- Work spanning multiple technical domains (e.g., backend + frontend + infra)
- Three or more independent tasks that benefit from parallel execution
- Implementation requiring quality assurance with integrated review
- Parallel review or investigation (e.g., security / performance / test coverage as separate concerns)

## When NOT to Use This Skill

- Only 1-2 tasks where parallelization adds no value
- Small changes within a single technical domain
- Research-only or investigation-only tasks
- **Heavily sequential work**: When most tasks have `blockedBy` dependencies, a single session is more efficient
- **Multiple agents editing the same file**: Later writes silently overwrite earlier changes (not a Git conflict — data loss)
- **Cost-sensitive contexts**: Teams consume several times more tokens than a single session

## Instructions

### 1. Analyze and Split Tasks

Analyze the implementation target and split it into tasks using the following criteria.

#### Splitting Criteria

| Criterion | Description |
|-----------|-------------|
| **Technical domain** | Split by language or layer (e.g., Python / TypeScript / Go / CSS). Minimize context switches |
| **Independence** | Identify tasks with no dependencies to enable parallel execution |
| **Granularity** | Target 1-3 files per agent. Too many files reduce accuracy |
| **File ownership** | Assign each file to exactly one agent. Never let multiple agents edit the same file |

#### File Conflict Prevention

⬛ MUST — **Never allow parallel edits to the same file.** A later write silently overwrites earlier changes.

Countermeasures:
- Define clear file ownership at task-splitting time
- If the same file must be changed by multiple tasks, serialize them with `blockedBy`
- As a last resort, have the leader integrate changes afterward

#### Define Task Dependencies

```
Independent tasks (parallel execution)
  Task A ─┐
  Task B ─┼──→ Dependent task (runs after prerequisites complete)
  Task C ─┘         │
                     └──→ Review task (runs after all implementation completes)
```

### 2. Determine Team Composition

Assemble the team with these roles:

| Role | subagent_type | Responsibility | mode |
|------|---------------|----------------|------|
| **Leader** | (self) | Task management, dependency control, applying review fixes | — |
| **Implementer x N** | `general-purpose` | Implementation for each technical domain | `bypassPermissions` |
| **Reviewer** | `review` | Quality verification of all deliverables | default |

#### Model Strategy

Choose a model for each agent based on the cost-quality tradeoff:

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

### 3. Create Team and Register Tasks

#### 3-1. Create the Team

```
TeamCreate
  team_name: "<feature-name>"
  description: "<purpose>"
```

#### 3-2. Create Tasks

Register each task with `TaskCreate`. Include:

- **subject**: Concise task name (imperative form)
- **description**: Detailed specification — enough for an agent to implement independently
  - File paths to create or modify
  - Implementation specs (schema, API contracts, function signatures, etc.)
  - Reference patterns to follow (file paths and code examples)
  - Constraints
- **activeForm**: Display text while in progress (present continuous)

#### 3-3. Set Dependencies

Use `TaskUpdate` with `addBlockedBy`:
- Independent tasks: No blockers (run in parallel)
- Dependent tasks: Specify prerequisite task IDs
- Review task: Specify all implementation task IDs

### 4. Launch Implementation Agents

⬛ MUST — **Launch agents for independent tasks simultaneously (multiple Task tool calls in a single message).**

#### Prompt Design (Context Sufficiency Is Critical)

Agents run in isolated sessions with no shared context. Include all necessary information in the prompt. Vague instructions directly degrade output quality.

Include the following in each agent's launch prompt:

```
1. Role name and team name
2. Assigned task IDs
3. Detailed implementation specs per task (file paths, code examples, constraints)
4. Reference patterns from existing code (file paths + code excerpts)
5. Scope of files the agent may edit (explicit file ownership)
6. Post-completion steps: TaskUpdate to completed → TaskList for next task
```

#### Prompt Template

```
You are "<name>", a teammate on the "<team-name>" team.
Your job is to implement the following tasks:

## Your assigned tasks
- Task #N: <subject>
- Task #M: <subject>

## Task #N: <subject>

**Create file:** `<file-path>`

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
  model: "sonnet"          # For adaptive strategy
  run_in_background: true
```

### 5. Manage Progress

The leader follows this cycle:

1. **Receive completion notification** → Verify deliverables with the Read tool
2. **Check overall progress** with TaskList
3. **When all implementation tasks complete** → Send `shutdown_request` to implementation agents
4. **Launch the reviewer**

### 6. Conduct Review

#### Launch the Reviewer

Once all implementation tasks are complete, launch the reviewer:

```
Task tool:
  subagent_type: "review"
  name: "reviewer"
  team_name: "<team-name>"
```

Include in the reviewer prompt:
- List of files to review
- Design document requirements (review criteria)
- Review perspectives (design alignment, security, pattern consistency, error handling, etc.)

#### Handle Review Findings

⬛ MUST — **The leader applies review fixes directly.** Reasons:
- Most fixes span multiple files
- Re-launching implementation agents adds unnecessary overhead
- The leader holds the full context

Fix priority:
1. **Critical** → Fix immediately
2. **Major** → Fix unless intentional by design (document the rationale)
3. **Minor** → Recommended fix. Address with comments or small changes
4. **Informational** → Record only. Consider in future phases

### 7. Cleanup

1. Send `shutdown_request` to all agents
2. Confirm all agents have shut down
3. Run `TeamDelete` to remove team resources

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

**Fix**: Prefer template-based composition (see Examples below).

## Important Notes

- **Context sufficiency is paramount**: Agents run in isolated sessions. Quality degrades when the prompt lacks file paths, code examples, or existing patterns
- **Investigate existing patterns first**: Before launching the team, use Explore agents or Glob/Grep/Read to understand existing conventions
- **3-4 agents is optimal**: Too many increases coordination cost; too few reduces parallelism benefit
- **Launch the reviewer after implementation**: Reviewing mid-implementation only increases churn
- **The leader handles fixes**: Re-launching agents for review fixes is inefficient
- **Embed best practices in the skill**: Patterns that apply automatically are more valuable than ones that rely on memory

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
  reviewer (opus)       → Full review (launched after implementation completes)

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
  reviewer (sonnet)   → Full review (launched after implementation completes)

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

Assign each agent exactly one review perspective to ensure analysis depth.
```
