# Scoped Re-Review Prompt Template

Use this when dispatching the re-review after the fix round.

```
Subagent (role: reviewer):
  description: "Re-review Task N fixes"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
         model inherits the session's most expensive one]
  prompt: |
    Verdict each finding and inspect the fix diff — nothing else.

    ## The Task

    Read the task brief: [BRIEF_FILE]

    ## Project Review Guidance

    If `docs/REVIEW-GUIDANCE.md` exists at the repository root, read it.
    It is reviewer-only. Apply its project-wide review guidance and report
    any conflict with the task requirements instead of guessing.

    ## The Findings Under Verification

    [FINDINGS]

    ## The Fix

    Read the implementer's report: [REPORT_FILE]

    **Fix base:** [FIX_BASE_SHA]  **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Your evidence is the findings list, the report's fix results, and the
    diff file — read each once. Leave the working tree untouched and
    dispatch no subagents. If the diff file is missing, fetch it with
    `git diff --stat [FIX_BASE_SHA]..[HEAD_SHA]` and
    `git diff [FIX_BASE_SHA]..[HEAD_SHA]`.

    Findings outside the fix diff go to the ledger and never extend the loop.
    Report them under Out-of-Scope Observations.

    The report's fix results are the test evidence: confirm each row names
    the covering test command and its output, and verify the claims
    against the diff. Take at most one focused test run, on a specific
    doubt no reported run answers.

    ## Output Format

    Your final message is the report itself, beginning with the first
    finding's verdict. Every line is a verdict, a finding with file:line,
    or a check you ran.

    ### Finding Verdicts

    For each finding, in order:
    - **[finding one-liner]** — ADDRESSED | NOT ADDRESSED, with file:line
      evidence. "Attempted" is not addressed: the specific defect must no
      longer exist.

    ### New Breakage in the Fix Diff

    Anything the fix broke or introduced, with severity
    (Critical/Important/Minor) and file:line. "None" if clean.

    ### Out-of-Scope Observations

    "None" if none.

    ### Verdict

    **Fix round:** [All findings addressed, no new Critical/Important
    breakage | Findings remain open] — list the open ones.
```

**Placeholders:**
- `[MODEL]` — REQUIRED: reviewer model per SKILL.md Model Selection; scoped
  re-reviews of small fix diffs take a cheap-to-mid tier
- `[BRIEF_FILE]` — the task brief (the same file the implementer worked from)
- `[FINDINGS]` — the Critical/Important findings and spec gaps from the
  previous review, copied verbatim, one per bullet
- `[REPORT_FILE]` — the implementer's report file, with fix reports appended
- `[FIX_BASE_SHA]` — the head the previous review saw
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — the path printed by
  `scripts/review-package --plan PLAN_FILE FIX_BASE HEAD`
