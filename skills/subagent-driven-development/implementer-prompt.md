# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Subagent (role: implementer):
  description: "Implement Task N: [task name]"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    Read your task brief first: [BRIEF_FILE]
    It is your requirements, with the exact values to use verbatim.

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Your Job

    Work from: [directory]

    A guard or negative assertion counts only when you have seen it fail
    against code that lacks the guard, not against a missing module.
    Report the command and the failing output in TDD Evidence, one line
    per guard.

    Do NOT dispatch subagents of your own for review.

    Fix a bug outside your task inline when it is trivial and tightly
    coupled to your change; otherwise report it as a concern for the
    controller. Never expand your diff chasing it.

    ## Verification

    While iterating, run the focused test for what you're changing. Before
    committing, run the packages your diff touches and direct consumers of
    any shared contract you changed — once each, never the whole workspace.
    Use the project's quiet-run wrapper when it exists. Read back exit
    status, pass count, and any failure tail only.

    Stop and report BLOCKED or NEEDS_CONTEXT when the task needs a
    decision or information you don't have — say what you're stuck on,
    what you tried, and what you need.

    ## After Review Findings

    Fix the findings, re-run the tests covering the amended code, and
    append this table to your report file:

    | Finding | Commit | Covering test command | Result |
    |---|---|---|---|

    `Result` is the command's last passing line, pasted.

    ## Report Format

    Write your full report to [REPORT_FILE]:
    - What you implemented (or attempted, if blocked)
    - What you tested and the results
    - **TDD Evidence** (if TDD was required): RED — command, failing
      output, why that failure was expected; GREEN — command and passing
      output; for each guard, the seen-red command and output

    Then report back with ONLY (under 15 lines):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits created (short SHA + subject)
    - One-line test summary
    - Your concerns, if any
    - The report file path

    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
    itself.
```
