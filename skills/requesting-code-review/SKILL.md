---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git merge-base origin/main HEAD)  # or the base you recorded before the work began
HEAD_SHA=$(git rev-parse HEAD)
```

Never use `HEAD~1` as the base — it silently drops all but the last commit
of a multi-commit change, and the reviewer approves a diff that isn't the
work.

**2. Build the review package** with `review-package` from the
subagent-driven-development skill's `scripts/` directory:
```bash
../subagent-driven-development/scripts/review-package $BASE_SHA $HEAD_SHA
```

It writes the commit list, stat summary, and the diff with extended context
to one file and prints the path. Pass that path as `{DIFF_FILE}` — the
reviewer reads one file instead of re-deriving the diff, and the diff never
enters your own context. Skip this step only if the script isn't reachable;
then pass `None` and the reviewer falls back to git commands.

**3. Dispatch code reviewer subagent:**

Dispatch a subagent on the `reviewer` route (specialty `code`) from the session routing brief, filling the template at [code-reviewer.md](code-reviewer.md). Pass the author's model so the resolver can keep the review independent.

Do not read `docs/REVIEW-GUIDANCE.md` yourself. The reviewer template loads it
when it exists. Supply only concise review-specific nuance from the approved
requirements and concrete risks; use `None` when there is no useful nuance.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{REVIEW_NUANCE}` - Concise review-specific context or concrete risks
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DIFF_FILE}` - Review package path from step 2 (`None` if unavailable)

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

../subagent-driven-development/scripts/review-package $BASE_SHA $HEAD_SHA
  wrote /repo/.toolbelt/sdd/review-a7981ec..3df7661.diff: 3 commit(s), 21184 bytes

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/toolbelt/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DIFF_FILE: /repo/.toolbelt/sdd/review-a7981ec..3df7661.diff

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
