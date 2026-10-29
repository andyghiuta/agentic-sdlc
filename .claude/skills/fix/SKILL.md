---
name: fix
description: The light path of the agentic SDLC, for a bug or a small change that needs no design decisions — proves the root cause (or locates the code), gets one Senior Dev confirmation, builds under the same TDD and independent per-task review as /implement, and closes on a final Senior Dev gate. Escalates to /feature as soon as the change outgrows its limits. Use when the user invokes /fix.
argument-hint: "[fix-slug] [what's wrong or what to change]"
disable-model-invocation: true
---

# /fix — the light path

You are the orchestrator for a fix. It's the full methodology with the
parts that only pay off for a real feature taken out: no spec
validation, no Gherkin, no design artefacts, no planner, no feature-wide
review. What stays is what keeps a small change honest: evidence before a
fix, a failing test first, an independent reviewer before every commit,
the loop caps, branch safety, and a human at both ends.

The same rule as `/implement` applies: **you never write or edit
production code or tests yourself.** `task-implementer` writes them,
`task-reviewer` checks them, and you sequence, commit, keep `fix.md`, and
talk to the user. Keep your own context small: don't read code, diffs or
test logs yourself; the agents' reports are your evidence.

## Before you start

- **Read the project's `CLAUDE.md`**, at the root of the project you're
  working in, if you haven't this session. You need the settings
  placeholders, `{{REPO_MODE}}`, the Components table (if present), the
  `/fix` limits, the loop-cap table and the Worktrees section. Don't look
  for it relative to this skill's own folder: when the skill is installed
  as a plugin, the files beside it belong to the plugin, not the project.
  If the project's `CLAUDE.md` is a component settings file (it has a
  **Hub** line), read the hub's `CLAUDE.md` as well.
- **Agent names.** Installed in the project's `.claude/`, the agents this
  skill uses go by the names written here (`fix-investigator`). Installed
  as the `agentic-sdlc` plugin, each one is registered as
  `agentic-sdlc:<name>`. Use whichever form your agent list shows.
- **Resolving a component** works exactly as in `/implement`: look up
  its `location`, confirm it's on disk, read its own `CLAUDE.md` for
  `{{TEST_CMD}}`, `{{LINT_CMD}}`, `{{SCHEMA_CHECK_CMD}}`,
  `{{MAIN_BRANCH}}` and `{{WORKTREE_SETUP_CMD}}`, and run every git
  command as `git -C <path> ...`.
  Skip this for `single-repo`.

## 0. Set up

Ask for a short kebab-case slug if the user didn't give one
(`null-total-on-empty-cart`). The fix's one artefact is
`{{DOCS_ROOT}}/fixes/<fix-slug>.md`, in `{{HUB_REPO}}` for
monorepo/multi-repo. If it already exists, this is a **resume**: see
Resume below.

## 1. Understand

Play the request back to the user in two or three sentences: what's wrong
(or what should change), where, and how you'll know it's fixed. Say
whether you read it as a **bug** (something does what it shouldn't) or a
**change** (it works as built, and should work differently). For
monorepo/multi-repo, name the components you think it touches. Ask at
most two questions, and only ones whose answers change what gets
investigated. This is not the `/feature` interview: if you find you need
more than two, or the user's answers open up new behaviour, it probably
isn't a fix. Say so and offer `/feature`.

Write `fix.md` with the **Request** (the user's words, verbatim) and
**Understanding** sections, and `Status: investigating`, before moving
on.

## 2. Investigate

Dispatch `fix-investigator` with the request, your play-back, the mode,
and (monorepo/multi-repo) the touched components with their resolved
paths. Copy its report into `fix.md` without softening it: Reproduction,
Root cause or Current behaviour, Tasks, Must not get wrong, and Limits.
Log each investigation round with its number and verdict, so the cap
holds across a resume.

- **READY** → set `Status: awaiting gate 1`, then step 3.
- **CANNOT REPRODUCE** → put its questions to the user, then continue the
  same investigator with the answers verbatim (or dispatch a fresh one
  with `fix.md`'s path if your tools can't continue an agent). This is
  the **investigation loop, capped at 2 rounds** (`CLAUDE.md`). Cap hit →
  **hard stop**: set `Status: BLOCKED`, log "cannot reproduce", and tell the
  user what was tried. Don't let anyone fix a bug nobody has seen.
- **ESCALATE** → step 2a.

### 2a. Escalate to `/feature`

Set `Status: ESCALATED` and log the limits hit and the evidence. Tell the
user which limit it hit and why, and that the next step is `/feature`
(ideally in a fresh session), with `fix.md` as the starting request:
`requirements-interviewer` can read it instead of starting from nothing.
If the user disagrees with the call (say, the "schema change" is a
default value they consider trivial), that's their decision as Senior
Dev: log the override and their reason in `fix.md`, set
`Status: awaiting gate 1`, and carry on to step 3. Don't escalate or
overrule silently either way.

The same applies later, when the work hits a limit after all (it needs a
migration, a contract field, a third task): `task-implementer` reports
it, or `task-reviewer` returns **ESCALATE**. Stop Build, set
`Status: ESCALATED`, and put it to the user. This is not a fix round: don't send
it back to the implementer. Work already committed stays committed; say
which commits exist.

## 3. Gate 1 — Senior Dev confirms the fix

Present `fix.md` to the user, acting as Senior Dev: the reproduction, the
root cause (or current behaviour), the task(s) with their `done-when`
conditions, and the limits check. If the change alters what users see,
suggest bringing the PM/BA in for this gate too. Get an explicit yes, or
specific changes (edit `fix.md`, re-dispatch the investigator only if a
change affects the root cause).

In the same message, ask the setup questions:

- **Worktree.** Offer to build in a worktree, default **no**, per
  `CLAUDE.md`'s Worktrees section. Skip the question if the session is
  already running in one. If the user says yes, set it up as that section
  describes (it creates `fix/<fix-slug>` in the worktree and leaves the
  main checkout alone), record each one in `fix.md`'s `Worktree` line,
  and skip the branch question.
- **Branch** (no worktree). Check the current branch in each touched
  component's repo. If one is on `{{MAIN_BRANCH}}`, offer to create
  `fix/<fix-slug>` there, and create it only on a yes. Never commit to
  `{{MAIN_BRANCH}}`, and never pass `--no-verify`.

On approval, log it with a timestamp and set `Status: building`.

## 4. Build

Add a **Progress** table to `fix.md`:

```markdown
## Progress

| Task | Component | Status | Rounds | Commit SHA |
|---|---|---|---|---|
| T1 | service-api | pending | 0 | — |
```

(Drop `Component` for `single-repo`.) Then, for each task in order:

1. Mark it `in-progress`.
2. Dispatch a fresh `task-implementer`, scoped to the component's path
   (or its worktree), with the task id, the path to `fix.md` as the
   task's source (in place of `plan.md`), and the component's resolved
   commands. Its `context` is `fix.md`'s Root cause (or Current
   behaviour) and Must not get wrong sections. For a bug, the first
   `done-when` condition is the reproduction test: its RED must fail for
   the reason in the Root cause, which is the proof the test pins the
   real bug.
3. Dispatch a fresh `task-reviewer` with the same scope, task id, source
   and commands.
4. **PASS** → commit (branch check, `git add` of the task's files, commit
   with the fix slug and task id in the message, SHA lookup, in one
   chained command), record the SHA and `done`.
   **FAIL** → the **per-task fix loop, capped at 5 rounds**, exactly as in
   `/implement` Phase 4: send the findings verbatim to the same
   implementer, its new report to the same reviewer, escalate to a fresh
   `opus` implementer at round 3, and at round 5 mark the task `BLOCKED`
   with the last findings and stop.
   **ESCALATE** → step 2a, not a fix round.

When every task is `done`, set `Status: awaiting gate 2`.

As in `/implement`, batch the bookkeeping: the commit in one command, and
the `fix.md` update sent alongside the next dispatch.

## 5. Gate 2 — Senior Dev signs off

Present to the user, acting as Senior Dev: each task's reviewer verdict
and commit SHA, the suite status per touched component (from the
reviewer's own run), and the root cause the fix addressed. Ask them to
try the fix themselves, for a bug by repeating the original reproduction
steps: the test proves the code path, the human proves the symptom is
gone. Close only on an explicit yes, then log it and set `Status: done`.

Once approved, you may open a PR per touched component (using whatever
VCS tooling is available), linking `fix.md`. Do **not** merge it: that's
Phase 6, human-only, same as a feature. If you built in a worktree,
remind the user it's still there and offer to remove it (see
`CLAUDE.md`'s Worktrees section); remove it only on a yes.

If PR comments come in later, handle them the way `/implement review`
layer 4 does: `external-review-handler` per comment, with `fix.md` as the
spec, its verdicts copied into `fix.md`'s Log, and confirmed ones through
the implementer and reviewer. They continue the round counter of the
task they touch: 5 rounds in total for that task, Build's included.

## Resume

If `fix.md` exists, go by its `Status`:

- `ESCALATED`, `BLOCKED` or `done` → stop and tell the user where it
  stands.
- `investigating` → step 2, counting the rounds already in the Log.
- `awaiting gate 1` → step 3.
- `building` → step 4, from the first task that isn't `done`.
- `awaiting gate 2` → step 5.

Before trusting a `done` task, check its commit SHA is still in the
branch history, and treat an `in-progress` task as not yet reviewed, as
in `/implement`. If the `Worktree` line records a path, check it still
exists and is on the recorded branch (`git -C <path> branch
--show-current`); if it's gone, stop and ask the user rather than
recreating it on top of commits that may only exist there.

## `fix.md` layout

```markdown
# Fix — <fix-slug>

Status: investigating | awaiting gate 1 | building | awaiting gate 2 | done | ESCALATED | BLOCKED
Mode: bug | change
Worktree: no | <component or repo>: <path> (branch <name>), ...

## Request          (verbatim)
## Understanding    (your play-back, and the user's answers)
## Reproduction     (bug mode)
## Root cause       (bug mode) / Current behaviour (change mode)
## Must not get wrong
## Limits
## Tasks            (T1, maybe T2, in plan.md task shape)
## Progress
## Log              (gate approvals, escalations, cap hits, with timestamps)
```
