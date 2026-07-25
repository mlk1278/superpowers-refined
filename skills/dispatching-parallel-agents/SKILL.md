---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

Subagents never inherit your session's context or history — you construct exactly what they need. That isolation is the whole point: it keeps them focused, and it preserves your own context for coordination.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

**Use when:** 3+ test files failing with different root causes, or multiple subsystems broken independently — each problem understandable without context from the others, no shared state between investigations.

**Don't use when:**
- **Failures are related** — fixing one might fix others. Investigate together first.
- **You need full system state** — understanding requires seeing the whole picture.
- **Exploratory debugging** — you don't know what's broken yet.
- **Shared state** — agents would edit the same files or contend for the same resources.

## The Pattern

### 1. Identify independent domains

Group failures by what's broken — tool approval flow, batch completion, abort handling. Each domain is independent: fixing tool approval doesn't affect abort tests.

### 2. Give each agent a focused task

Specific scope (one test file or subsystem), clear goal, constraints on what NOT to touch, and an explicit expected output.

### 3. Dispatch in parallel

Issue all dispatches in the **same response** — that is what makes them run concurrently. One per response is sequential.

```text
Subagent (role: implementer): "Fix agent-tool-abort.test.ts failures"
Subagent (role: implementer): "Fix batch-completion-behavior.test.ts failures"
Subagent (role: implementer): "Fix tool-approval-race-conditions.test.ts failures"
# All three run concurrently.
```

### 4. Review and integrate

Read each summary. Check whether agents edited the same code. Run the affected integration scope — the suites the waves touched, escalating by risk, not the whole workspace. Then spot check: agents can make systematic errors that each summary reports as success.

## Agent Prompt Structure

Focused (one problem domain), self-contained (all context needed), and specific about what to return.

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Return: Summary of what you found and what you fixed.
```

## Common Mistakes

**❌ Too broad:** "Fix all the tests" - agent gets lost
**✅ Specific:** "Fix agent-tool-abort.test.ts" - focused scope

**❌ No context:** "Fix the race condition" - agent doesn't know where
**✅ Context:** Paste the error messages and test names

**❌ No constraints:** Agent might refactor everything
**✅ Constraints:** "Do NOT change production code" or "Fix tests only"

**❌ Vague output:** "Fix it" - you don't know what changed
**✅ Specific:** "Return summary of root cause and changes"
