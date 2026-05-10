---
name: token-cost-optimizer
description: >
  Use before a large task when model choice, context size, or parallelism could drive up
  billed token usage. Estimates cost pressure early and applies reduction tactics before running.
  Trigger: "optimize tokens", "reduce cost", "token budget", or before large multi-file tasks.
user-invocable: true
---

# Token Cost Optimizer

Proactive cost-control skill. Reduce metered usage before and during a task.

## When to Use

- Before large task that scans many files or runs long
- Before fleet/autopilot modes where parallelism multiplies spend
- When staying inside a token budget
- Trading small quality reduction for large cost reduction on routine work

## Cost Drivers (priority order)

1. **Model selection** — premium models cost more; use cheapest that meets quality bar
2. **Context size** — wider scans + larger prompts = more tokens
3. **Parallel agent count** — fleet multiplies model interactions
4. **Autonomous depth** — long autopilot runs accumulate usage unattended

## Workflow

### 1. Estimate task shape

- How many files must be read?
- Does task need premium model?
- Is work truly parallelizable?
- Can context be narrowed before starting?

If unclear → reduce uncertainty before paying for large blind run.

### 2. Right-size model

| Task type | Model |
|-----------|-------|
| Search, routing, simple summaries | Fast / cheap |
| Normal implementation + planning | Standard |
| Security, architecture, high-risk review | Premium (justified only) |
| Mixed/uncertain workload | Auto selection |

### 3. Cut context before running

Good moves:
- Compact stale conversation history before large new task
- Narrow repo surface before asking for implementation
- Prefer targeted file reads over broad codebase scans
- Split unrelated requests instead of bundling into one giant prompt

### 4. Be selective with fleet/autopilot

Use fleet when: work is large, subtasks mostly independent, context already constrained.
Avoid fleet when: task is sequential, you need exploratory back-and-forth, every subagent needs same giant context.

### 5. Write cost-aware plan before large run

```
Model: Auto
Context: compact first, limit to docs/ and src/auth/
Execution: sequential until scope clear, fleet only for independent test files
Stop rule: switch to manual if task expands beyond approved surface
```

## Red Flags

- Premium model used for routing/search/boilerplate
- Fleet planned before work decomposed into independent subtasks
- Long stale conversation with no compact step
- Task brief doesn't justify premium model

## Verification

- [ ] Model tier matches task risk and complexity
- [ ] Context narrowed before large autonomous/parallel runs
- [ ] Fleet only where parallelism has clear payoff

---
*Adapted from: https://github.com/drvoss/everything-copilot-cli — MIT License*
