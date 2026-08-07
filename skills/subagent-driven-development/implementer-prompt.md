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

    A guard or negative assertion counts only **seen red**: its TDD RED,
    or whatever other evidence convinced you it can fail — report it.

    All review dispatch belongs to the controller. Do not dispatch
    subagents of your own — a review you commission yourself does not
    count and wastes a review cycle.

    If you discover a bug outside your task: fix it inline when it is
    trivial and tightly coupled to your change; otherwise report it as a
    concern for the controller to plan. Never expand your diff chasing it.

    ## Verification

    While iterating, run the focused test for what you're changing. Before
    committing, run the affected package suite(s) once — the packages your
    diff touches plus direct consumers of any shared contract you changed —
    never the whole workspace; that suite belongs to the branch's final
    gate. Use the project's quiet-run wrapper when it provides one and read
    back exit status, pass count, and any failure tail only.

    Stop and report BLOCKED or NEEDS_CONTEXT when the task needs a
    decision or information you don't have — say what you're stuck on,
    what you tried, and what you need.

    ## After Review Findings

    If a reviewer finds issues and you fix them, re-run the tests covering
    the amended code and append the results to your report file — your
    report is the evidence.

    ## Report Format

    Write your full report to [REPORT_FILE]:
    - What you implemented (or attempted, if blocked)
    - What you tested and the results
    - **TDD Evidence** (if TDD was required): RED — command, failing
      output, why that failure was expected; GREEN — command and passing
      output
    - Files changed
    - Any issues or concerns

    Then report back with ONLY (under 15 lines — the detail lives in the
    report file):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits created (short SHA + subject)
    - One-line test summary (e.g. "14/14 passing, output pristine")
    - Your concerns, if any
    - The report file path

    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
    itself — the controller acts on it directly.
```
