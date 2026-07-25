---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

A skill is a reference guide for a proven technique, pattern, or tool — not a narrative about how you solved something once.

Skills are behavior-shaping code. You write them the way you write code under TDD: watch an agent fail without the skill, write the skill against that specific failure, verify the failure stops, then close the loopholes the agent finds next.

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** `toolbelt:test-driven-development` defines the RED-GREEN-REFACTOR cycle this adapts. For Anthropic's official authoring guidance, see [anthropic-best-practices.md](anthropic-best-practices.md).

## The Iron Law

```
NO NEW BEHAVIOR-SHAPING GUIDANCE WITHOUT A FAILING TEST FIRST
```

Write the skill before seeing the baseline? Delete it. Start over.

**No exceptions:**
- Not for "simple additions"
- Not for "just adding a section"
- Don't keep untested guidance as "reference"
- Don't "adapt" it while running tests
- Delete means delete

**Scope.** This gate governs guidance that changes what an agent does — a new skill, a new rule, a new gate. It does not govern editing what already exists: condensing, restructuring, fixing a broken link, or rewording a rule whose behavior you are not changing. Those need the change to be *correct*, not a pressure scenario. If you can't tell which you're doing, ask: would an agent behave differently after this edit? Yes → baseline first.

## When to Create a Skill

**Create when** the technique wasn't intuitively obvious, you'd reference it again across projects, and it applies broadly.

**Don't create for** one-off solutions, standard practices documented elsewhere, project-specific conventions (those go in the consuming project's instructions file), or mechanical constraints — if regex or a validator can enforce it, automate it and save documentation for judgment calls.

**Split by trigger, not by size.** A distinct entry condition earns its own skill and its own description, however short the body. One description straddling two entry conditions degrades both.

## Structure

```
skills/skill-name/
  SKILL.md              # required
  supporting-file.*     # only for heavy reference (100+ lines) or reusable tools
```

Flat namespace, all skills searchable together. Keep principles, concepts, and code patterns under ~50 lines inline. Split out API references, comprehensive syntax, and scripts — those get loaded only when needed.

Frontmatter requires exactly two fields, `name` and `description`, max 1024 characters total ([full spec](https://agentskills.io/specification)). Name uses letters, numbers, and hyphens only.

A typical body: overview and core principle → when to use → the pattern or contract → quick-reference table → common mistakes. Deviate freely; that order is a starting point, not a template to fill in.

## The Description Field

**This is the highest-leverage line in any skill.** It decides whether the skill fires at all. An agent reads descriptions to choose what to load, so it must answer one question: "should I read this right now?"

**Describe when to use it. Never summarize what it does.**

```yaml
# ❌ Summarizes workflow — agents follow this instead of reading the skill
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ❌ Process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ❌ First person, vague, no trigger
description: I can help you with async tests when they're flaky

# ✅ Triggering conditions only
description: Use when executing implementation plans with independent tasks in the current session

# ✅ Describes the problem, not the mechanism
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

**Why this is a hard rule, not a style preference:** a description summarizing "code review between tasks" caused an agent to run ONE review when the skill body specified TWO. It followed the description and never read the body. Removing the workflow summary fixed it. A description that summarizes workflow creates a shortcut agents will take, and the skill body becomes documentation they skip.

Write in third person (it lands in the system prompt). Use concrete triggers, symptoms, and error strings an agent would search for — "Hook timed out", "ENOTEMPTY", "flaky", "zombie", "pollution". Describe the *problem* (race conditions) rather than language-specific symptoms (`setTimeout`), unless the skill really is technology-specific — then make that explicit in the trigger.

## Match the Form to the Failure

Before writing guidance, classify the baseline failure. The form that bulletproofs one failure type measurably backfires on another.

| Baseline failure | Right form | Wrong form |
|---|---|---|
| Skips/violates a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags | Soft guidance ("prefer...", "consider...") |
| Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | Positive recipe or contract: state what the output IS — its parts, in order | Prohibition list ("don't restate", "never narrate") |
| Omits a required element from something they already produce | Structural: REQUIRED field or slot in the template they fill in | Prose reminders near the template |
| Behavior should depend on a condition | Conditional keyed to an observable predicate ("if the brief exists, reference it") | Unconditional rule + exemption clauses |

**Why prohibitions backfire on shaping problems:** under a competing incentive ("make the prompt self-contained"), agents negotiate with "don't X". In head-to-head wording tests on dispatch-prompt guidance, the prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control — micro-test your own case rather than assuming, but never reach for the prohibition by default. A recipe leaves nothing to negotiate: the output matches the stated shape or it doesn't.

**Rules for whichever form you pick:**
- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation — appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate.
- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. If part of the output must be exempt, restructure so the rule can't reach it.

## Bulletproofing Against Rationalization

For discipline failures only — an agent that knows the rule and skips it under pressure. For wrong-shaped output or omitted elements, this toolkit backfires; use the forms above.

Agents are smart and will find loopholes. Four techniques, all sourced from what baseline testing actually caught:

**Close every loophole explicitly.** Don't just state the rule, forbid the specific workarounds. "Write code before test? Delete it." invites keeping it as reference. The version that holds adds: *Start over. No exceptions: don't keep it as "reference", don't "adapt" it while writing tests, don't look at it, delete means delete.*

**Cut off spirit-vs-letter arguments early:**

```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

**Build a rationalization table.** Every excuse an agent made during baseline testing gets a row and a one-line reality. Verbatim excuses beat paraphrases — you're matching the thought the agent is about to have.

**Create a red flags list** of the thoughts themselves, so an agent mid-rationalization can self-check, ending with what to do: *All of these mean: Delete code. Start over with TDD.*

Understanding why these work helps you apply them systematically — see [persuasion-principles.md](persuasion-principles.md) for the research foundation (Cialdini, 2021; Meincke et al., 2025).

## RED-GREEN-REFACTOR

**RED — baseline.** Run the pressure scenario with a subagent WITHOUT the skill. Document what they chose, which pressures triggered the violation, and the rationalizations **verbatim**. You cannot write the skill until you have seen this.

**GREEN — minimal skill.** Address those specific rationalizations. No content for hypothetical cases. Re-run the same scenarios; the agent should comply.

**REFACTOR — close loopholes.** New rationalization? Add its counter. Re-test until bulletproof.

**Test each skill through the full cycle before starting the next one.** Batching is not more efficient; it just defers finding out that the first one doesn't work.

Full methodology — writing pressure scenarios, pressure types (time, sunk cost, authority, exhaustion), plugging holes, meta-testing — is in [testing-skills-with-subagents.md](testing-skills-with-subagents.md).

## Micro-Testing Wording

Pressure scenarios are the final gate but are slow per iteration. Verify the wording itself first:

1. **One fresh-context sample per call** — a raw API call, or a single-shot subagent if you don't have API access. System prompt = the realistic context the guidance will live in (the full skill or prompt template, not the guidance in isolation); user message = a task that tempts the failure.
2. **Always include a no-guidance control.** If the control doesn't exhibit the failure, there is nothing to fix — stop, don't author the guidance.
3. **5+ reps per variant.** Single samples lie.
4. **Manually read every flagged match.** Score programmatically if you like, but template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
5. **Variance is a metric.** When guidance lands, reps converge on the same shape. Five different interpretations across five reps means the wording isn't binding — tighten the form before adding words.

Micro-tests verify wording; they do not replace pressure scenarios for discipline skills.

## Testing by Skill Type

| Type | Test with | Success criteria |
|---|---|---|
| **Discipline** (TDD, verification-before-completion) | Academic questions, then pressure scenarios — 3+ pressures combined | Follows the rule under maximum pressure |
| **Technique** (condition-based-waiting, root-cause-tracing) | Application scenarios, variations, missing-information tests | Applies the technique to a new scenario |
| **Pattern** (reducing-complexity, information-hiding) | Recognition scenarios, application, counter-examples | Identifies when *and when not* to apply it |
| **Reference** (APIs, command guides) | Retrieval scenarios, application, gap testing | Finds and correctly applies the information |

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

**All of these mean: Test before deploying. No exceptions.**

## Naming

Name by what you DO or by the core insight, verb-first, gerunds for processes:

- ✅ `condition-based-waiting` > `async-test-helpers`
- ✅ `root-cause-tracing` > `debugging-techniques`
- ✅ `flatten-with-flags` > `data-structure-refactoring`
- ✅ `creating-skills` > `skill-creation`

## Cross-Referencing Other Skills

Use the skill name with an explicit requirement marker — `**REQUIRED BACKGROUND:** You MUST understand toolbelt:systematic-debugging`. A bare `See skills/testing/test-driven-development` leaves it unclear whether it's required.

**Never use `@` links.** `@skills/.../SKILL.md` force-loads the file immediately, burning context before you need it.

## Flowcharts

Use one ONLY for a non-obvious decision point, a process loop where you'd stop too early, or an "A vs B" choice. Never for reference material (use tables), code (use markdown blocks), or linear instructions (use numbered lists). Labels must carry semantic meaning — `helper1`, `step3` are useless in a diagram.

Style rules are in `graphviz-conventions.dot`. To show a skill's diagrams to your human partner:

```bash
./render-graphs.js ../some-skill           # Each diagram separately
./render-graphs.js ../some-skill --combine # All diagrams in one SVG
```

## Code Examples

**One excellent example beats many mediocre ones.** Complete, runnable, from a real scenario, commented to explain WHY, ready to adapt. Pick the language that fits the domain — TypeScript for testing techniques, shell or Python for system debugging.

Don't implement in five languages, don't write fill-in-the-blank templates, and don't invent contrived scenarios. You're good at porting; one great example is enough.

## Checklist

**IMPORTANT: Create a todo for EACH item.**

**RED:**
- [ ] Pressure scenarios written (3+ combined pressures for discipline skills)
- [ ] Run WITHOUT the skill — baseline behavior documented verbatim
- [ ] Patterns in the rationalizations identified

**GREEN:**
- [ ] Frontmatter valid: `name` (letters/numbers/hyphens), `description` starting "Use when...", third person, no workflow summary, under 1024 chars total
- [ ] Searchable keywords throughout — errors, symptoms, tools
- [ ] Addresses the specific baseline failures, nothing hypothetical
- [ ] Guidance form matches the failure type
- [ ] Behavior-shaping wording micro-tested against a no-guidance control (5+ reps, every flagged match read manually) — N/A for pure reference skills
- [ ] One excellent example; heavy reference and tools in separate files
- [ ] Run WITH the skill — agents now comply

**REFACTOR:**
- [ ] New rationalizations from testing identified and countered
- [ ] Rationalization table and red flags list built from all iterations
- [ ] Re-tested until bulletproof

**Ship:**
- [ ] Committed and pushed
