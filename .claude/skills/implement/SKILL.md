---
name: implement
description: Phases 3-5 (Plan, Build, Review) of the agentic SDLC — turns an approved design into an ordered task list, drives each task through TDD with an independent review before every commit, then runs a five-layer feature-wide review before the final human gate. Use when the user invokes /implement, /implement plan, /implement build, or /implement review, or wants to resume a feature that already has a plan.md/progress.md.
---

# /implement — Plan, Build, Review

You are the **orchestrator** for Phases 3-5. This is the one rule that
matters most in this skill: **you never write or edit production code or
tests yourself.** Every change goes through the `task-implementer`
subagent, one task at a time. Your job is to sequence subagents, enforce
the gates and loop caps, maintain `progress.md`, and talk to the human.

Read [`CLAUDE.md`](../../../CLAUDE.md) first if you haven't this session —
you need the settings placeholders, the layering rule, and the loop-cap
table below.

Prerequisite: Phase 2 must be complete and gated (`design/system-design.md`
exists and was approved). If it isn't, tell the user to run `/tech-design`
first.

## Argument handling

- `/implement` (no argument) — read `progress.md` if it exists and resume
  from wherever it says the feature stands (see Resume below). If no
  `plan.md` exists yet, start at Plan.
- `/implement plan` — run Plan only, then stop and report (useful for
  re-planning or reviewing the task breakdown before committing to Build).
- `/implement build` — run Build only. Requires an existing, gated
  `plan.md`.
- `/implement review` — run Review only. Requires Build to be complete
  (every task in `progress.md` is `done`).

## Phase 3 — Plan

1. Dispatch `implementation-planner` with the full feature folder. It
   reads spec, acceptance scenarios, and all design artefacts, scans the
   codebase, and writes `plan.md` (ordered tasks + coverage map) and an
   initialized `progress.md`.
2. Check the coverage map yourself: every acceptance scenario has at least
   one task, or an explicit, reasoned exclusion. If something's silently
   missing, send it back to `implementation-planner` before showing the
   plan to the user.
3. **Gate — Senior Dev / orchestrator confirms the plan with the user.**
   Walk through the task list and coverage map. Get explicit confirmation
   before writing any code. This gate has no automated loop — it's a
   conversation; iterate on the plan directly with the user as long as it
   takes.

### `progress.md` format

```markdown
# Progress — <feature-slug>

| Task | Status | Rounds | Commit SHA |
|---|---|---|---|
| T1 | pending | 0 | — |
| T2 | pending | 0 | — |
...

## Log
- <timestamp> — plan confirmed by human
```

Status values: `pending`, `in-progress`, `done`, `BLOCKED`. Update this file
after every task transition, not just at the end of Build — it's the
resume mechanism and the human's live view into where the feature stands.

## Phase 4 — Build

Process tasks from `plan.md` in order, respecting `depends-on`. For each
task:

1. **Branch safety check.** Confirm the current branch is not
   `{{MAIN_BRANCH}}` before doing anything. The git hook (see
   `hooks/pre-commit-branch-protection.sh`) is the backstop, not the only
   check — catch this yourself first and tell the user if you're
   unexpectedly on the protected branch.
2. Mark the task `in-progress` in `progress.md`.
3. Dispatch `task-implementer` with the task's fields. It writes the
   failing test, confirms RED for the right reason, writes minimal code,
   confirms GREEN plus lint plus schema-check.
4. Dispatch `task-reviewer` (independent context) against the result. It
   re-runs everything itself and returns PASS or FAIL with specifics.
5. **PASS** → commit (one commit per task, message referencing the task
   id), record the commit SHA and `status: done` in `progress.md`, move to
   the next task.
   **FAIL** → re-dispatch `task-implementer` in fix mode with the
   reviewer's findings, increment the task's round counter, go back to
   step 4. This is the **per-task fix loop, capped at 5 rounds**
   (`CLAUDE.md`).
   **Cap hit (round 5, still FAIL)** → mark the task `BLOCKED` in
   `progress.md` with the last reviewer findings attached, **halt the
   entire Build phase**, and report to the user. Do not skip the task and
   continue to the next one — downstream tasks may depend on this one, and
   silently proceeding would hide a real blocker.

### Resume

If `/implement build` (or bare `/implement`) is invoked and `progress.md`
already has tasks marked `done`, verify each recorded commit SHA is still
present in the branch's history (`git log` / `git show`) before trusting
it — don't just trust the file if the branch has been rebased or amended
out from under it. Continue from the first `pending` or `in-progress` task.
A task left `in-progress` from an interrupted run should be treated as not
yet reviewed — re-run step 4 onward for it rather than assuming partial
credit.

## Phase 5 — Review

Runs once every task in `progress.md` is `done`.

**Layer 1** (per-task review) is already satisfied by Build — nothing to do
here.

**Layer 2 — feature-wide.** Dispatch `feature-reviewer`. It re-runs the
full suite itself, checks acceptance coverage end to end, design/UX
fidelity, and a senior-bar security pass, and writes `review-report.md`.

**Layer 3 — architectural (optional).** For **major**-difficulty features
(per the Phase 2 triage recorded in `design/system-design.md`), or if the
user opts in for a lower-difficulty one, dispatch `architecture-reviewer`
against the full `git diff {{MAIN_BRANCH}}...HEAD`. Skip it otherwise —
don't run it by default on trivial/moderate changes.

**Layer 4 — external.** If there are external review comments (PR comments
on `{{VCS_HOST}}`, `{{ISSUE_TRACKER}}` comments, anything a human relays),
dispatch `external-review-handler` per finding before agreeing to act on
any of them.

**Fix loop.** Any blocking finding from layers 2-4 routes back to
`task-implementer` (scoped to the relevant files) and then back to the
layer that raised it, for re-verification. All of layers 2-4 together share
the **final review fix loop, capped at 5 rounds** (`CLAUDE.md`) — track a
single counter across all three layers, not one each.

**Cap hit, still blocking findings** → **hard stop.** Report the
unresolved findings plainly; this is not a state to push a PR out of.

**Layer 5 — the human.** Present `review-report.md` to the user acting as
Senior Dev: suite status, blocking findings (should be zero to reach this
point), advisories, full acceptance-coverage table. Ask them to run the app
themselves and look for what no agent thought to flag — this is not a
rubber-stamp step. **Gate: the Senior Dev is the final approver.** Exit
requires zero blocking findings, full suite green, every scenario green,
and the human's explicit sign-off.

## After the gate

Once the human approves, you may open a PR (using whatever VCS tooling is
available) summarizing the feature, linking the artefact folder, but do
**not** merge it — merging is Phase 6, manual, human-only, and backstopped
by the branch-protection hook. Point the user at
[`docs/PHASE-6-CHECKLIST.md`](../../../docs/PHASE-6-CHECKLIST.md) for what
comes next.
