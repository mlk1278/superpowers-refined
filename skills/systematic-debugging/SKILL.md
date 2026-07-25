---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

Use this for any technical issue — test failures, production bugs, unexpected behavior, performance problems, build failures, integration issues. **Especially** under time pressure, when "just one quick fix" seems obvious, or when you've already tried something that didn't work. A simple-looking issue has a root cause too, and rushing guarantees rework.

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**Read the error messages carefully.** Don't skip past errors or warnings — they often contain the exact solution. Read stack traces completely; note line numbers, file paths, error codes.

**Reproduce consistently.** Can you trigger it reliably, with what exact steps, every time? Not reproducible → gather more data, don't guess.

**Check recent changes.** Git diff and recent commits, new dependencies, config changes, environmental differences.

**In multi-component systems, gather evidence before proposing anything.** When the system has boundaries (CI → build → signing, API → service → database), instrument each one: log what data enters, what exits, whether environment and config propagated, and the state at each layer. Run once to find *where* it breaks, then investigate that component. A few `echo` statements at each layer will tell you that secrets reached the workflow but not the build script — which is the whole answer.

**Trace data flow when the error is deep in a call stack.** Where does the bad value originate? What called this with it? Keep tracing up until you find the source, and fix there rather than at the symptom. See [root-cause-tracing.md](root-cause-tracing.md) for the full technique.

### Phase 2: Pattern Analysis

Find similar working code in the same codebase — what works that resembles what's broken?

If you're implementing a known pattern, read the reference implementation **completely**. Don't skim. Partial understanding guarantees bugs.

List every difference between working and broken, however small. Don't assume "that can't matter." Then account for what the code depends on: other components, settings, config, environment, and the assumptions it makes.

### Phase 3: Hypothesis and Testing

**Form one hypothesis.** State it clearly and specifically: "I think X is the root cause because Y."

**Test it minimally.** The smallest possible change, one variable at a time. Don't fix multiple things at once.

**Verify before continuing.** Worked → Phase 4. Didn't work → form a *new* hypothesis. Do not stack more fixes on top.

**When you don't know, say so.** "I don't understand X" beats pretending. Ask, or research further.

### Phase 4: Implementation

**Create a failing test case first** — the simplest reproduction, automated if a framework exists, a one-off script if not. You must have this before fixing. Use `toolbelt:test-driven-development` to write it properly.

**Implement a single fix** addressing the identified root cause. One change. No "while I'm here" improvements, no bundled refactoring.

**Verify:** test passes, no other tests broken, issue actually resolved.

**If the fix doesn't work, stop and count how many you've tried.** Under 3 → return to Phase 1 and re-analyze with what you now know. **At 3 or more → stop and question the architecture.** Do not attempt fix #4 without that discussion.

### When 3+ Fixes Have Failed

The pattern that indicates an architectural problem: each fix reveals new shared state or coupling somewhere else, fixes start requiring "massive refactoring," and each one creates new symptoms elsewhere.

Stop and question fundamentals. Is this pattern sound? Are we sticking with it through sheer inertia? Should we refactor rather than keep fixing symptoms? **Discuss with your human partner before attempting more fixes.**

This is not a failed hypothesis. This is a wrong architecture.

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

**If 3+ fixes failed:** Question the architecture.

## Signals From Your Human Partner That You're Doing It Wrong

- "Is that not happening?" — you assumed without verifying
- "Will it show us...?" — you should have added evidence gathering
- "Stop guessing" — you're proposing fixes without understanding
- "Ultra-think this" — question fundamentals, not just symptoms
- "We're stuck?" (frustrated) — your approach isn't working

**When you see these:** STOP. Return to Phase 1.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

## When Investigation Reveals No Root Cause

If the issue is genuinely environmental, timing-dependent, or external: you've completed the process. Document what you investigated, implement appropriate handling (retry, timeout, clear error message), and add logging for next time.

**But:** most "no root cause" conclusions are incomplete investigation.

## Supporting Techniques

- [root-cause-tracing.md](root-cause-tracing.md) — trace bugs backward through the call stack to the original trigger
- [defense-in-depth.md](defense-in-depth.md) — add validation at multiple layers after finding root cause
- [condition-based-waiting.md](condition-based-waiting.md) — replace arbitrary timeouts with condition polling

**Related skills:** `toolbelt:test-driven-development` for the failing test in Phase 4, `toolbelt:verification-before-completion` to verify the fix before claiming success.
