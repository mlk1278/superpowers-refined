---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

Find the cause before changing the code. Reproduce the failure, gather evidence, and test one explanation at a time.

1. **Investigate.** Read the error message and the whole stack trace — line numbers, file paths, error codes; they often contain the answer. Reproduce it: exact steps, every time. Not reproducible means gather more data, not guess. Check recent changes — commits, new dependencies, config, environment. Trace the data flow: where does the bad value originate, and what passed it in? Keep going up until you reach the source. See [root-cause-tracing.md](root-cause-tracing.md).

2. **Analyze.** Find code in the same codebase that works and resembles what is broken. If you are following a reference implementation, read the relevant code and its assumptions before copying it. List every difference between working and broken, however small, and account for what the code depends on — other components, config, environment, assumptions. In a multi-component system (CI → build → signing, API → service → database), instrument each boundary: log what enters, what exits, and whether config and environment propagated. Use those results to narrow the failing boundary.

3. **Hypothesize.** State one hypothesis: "X is the root cause because Y." Test it with the smallest possible change, one variable at a time. It worked, go to step 4. It did not, return to step 1 with what you learned and form a new hypothesis rather than stacking another fix on top. If you do not understand something, say so and ask.

4. **Implement.** Write a failing test first — the simplest reproduction, automated where a framework exists, a script otherwise. Use `toolbelt:test-driven-development` to write it. Then make one fix addressing the root cause, with no bundled refactoring. Verify the test passes, no other test broke, and the original symptom is gone.

After three failed fixes, stop fixing. Repeated fixes that expose shared state, require broader refactoring, or create new symptoms may indicate a design problem. Question whether the design is sound and discuss it with your human partner before attempting a fourth fix.

If evidence identifies an environmental, timing-dependent, or external cause, record what you ruled out, implement handling (retry, timeout, a clear error), and add logging for next time. If the evidence is still inconclusive, say what remains unknown.

## Supporting techniques

- [root-cause-tracing.md](root-cause-tracing.md) — trace a bug backward through the call stack to its trigger
- [defense-in-depth.md](defense-in-depth.md) — validate at several layers once the root cause is known
- [condition-based-waiting.md](condition-based-waiting.md) — replace arbitrary timeouts with condition polling
