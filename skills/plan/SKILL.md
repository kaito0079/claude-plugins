---
name: plan
description: Forces planning mode following the 80% planning / 20% implementation principle. Creates a design document before any coding begins, covering problem analysis, approach selection, and structured implementation steps.
---

# Planning Mode (80/20 Rule)

Conduct thorough planning and create a design document before writing any code.

## When to Use This Skill

- Before implementing a new feature
- Before a large-scale refactoring
- Before a complex bug fix
- Before work involving architectural changes

## Instructions

**IMPORTANT: When this skill is invoked, do NOT start writing code immediately.**
**Spend 80% of your time on planning and 20% on implementation.**

### 1. Problem Analysis Phase

First, understand the problem precisely:

#### 1a. Gather Requirements
- What does the user want to achieve?
- What are the success criteria (what defines "done")?
- What are the constraints?

#### 1b. Investigate Current State
- Read the relevant parts of the existing codebase
- Identify affected files
- Review existing tests
- Check related API specifications

#### 1c. Define the Problem

Clearly articulate the problem in the following format:

```
## Problem Definition
**What**: [Target to implement/fix]
**Why**: [Reason this change is necessary]
**Constraints**: [Technical and business constraints]
**Impact Scope**: [Files and features affected by the change]
```

### 2. Approach Exploration Phase

Evaluate at least 2 alternative approaches:

```
## Approach A: [Name]
**Overview**: [1-2 sentence description]
**Pros**: [List of advantages]
**Cons**: [List of disadvantages]
**Effort**: [Relative effort - Small / Medium / Large]
**Risks**: [Potential risks]

## Approach B: [Name]
**Overview**: ...
```

### 3. Approach Selection Phase

Document the selected approach and rationale:

```
## Selected: Approach [X]
**Rationale**: [Specific reasons for selection]
**Trade-offs**: [Trade-offs accepted]
```

Confirm the selection with the user before proceeding to the next phase.

### 4. Design Document Creation

Create a design document with the following structure:

```
## Design Document

### Files to Change
| File | Change Type | Description |
|------|-------------|-------------|
| path/to/file | New / Modify / Delete | Summary |

### Database Changes (if applicable)
- Migration details
- Seeder changes

### API Changes (if applicable)
- Endpoints
- Request/response formats

### Test Plan
- Test cases to add
- Test data preparation

### Implementation Steps (ordered)
1. [First step]
2. [Next step]
3. ...

### Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
```

### 5. User Confirmation

Present the design document to the user and obtain approval.
**Do NOT begin implementation without approval.**

### 6. Implementation Phase

After approval, implement following the design document's implementation steps.
Report progress to the user after each step.

### 7. Retrospective

After implementation is complete, record any deviations from the design:
- Differences between the plan and actual implementation
- Lessons learned for future reference

## Important Notes

- "It's simple, no planning needed" is NOT allowed. If this skill is invoked, always follow this process
- If deviation from the design becomes necessary during implementation, consult the user
- If things are not working, do not force your way through. Return to planning mode
