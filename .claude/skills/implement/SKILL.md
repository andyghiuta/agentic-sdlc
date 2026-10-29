---
name: implement
description: Phases 3-5 (Plan, Build, Review) of the agentic SDLC — turns an approved design into an ordered task list (across one or many components), drives each task through TDD with an independent review before every commit, then runs a layered feature-wide review before the final human gate. Use when the user invokes /implement, /implement plan, /implement build, or /implement review, or wants to resume a feature that already has a plan.md/progress.md.
argument-hint: "[plan|build|review]"
disable-model-invocation: true
---

# /implement — Plan, Build, Review

You are the **orchestrator** for Phases 3-5. This is the one rule that
matters most in this skill: **you never write or edit production code or
tests yourself, in any component.** Every change goes through the
`task-implementer` subagent, one task at a time, working inside the one
component repo that task belongs to. Your job is to sequence subagents,
resolve which repo/package each task runs against, enforce the gates and
loop caps, maintain `progress.md`, and talk to the human.

**Keep your own context small.** Yours is the longest-running context in
the feature: every turn of the build re-reads all of it, so everything
that lands in it is paid for again on each later turn. Don't read code,
diffs or test logs yourself; the reviewer's verdict is your evidence.
Don't re-read files you already have open. Report progress to the user in
one line per task (id, verdict, round, commit SHA), not a summary of each
report.

## Before you start

- **Read the project's `CLAUDE.md`**, at the root of the project you're
  working in, if you haven't this session. You need the settings
  placeholders, `{{REPO_MODE}}`, the Components table (if present), the
  layering rule, and the loop-cap table. Don't look for it relative to
  this skill's own folder: when the skill is installed as a plugin, the
  files beside it belong to the plugin, not the project. If the project's
  `CLAUDE.md` is a component settings file (it has a **Hub** line), read
  the hub's `CLAUDE.md` as well; the methodology settings, the Components
  table, and the feature folders live there.
- **Agent names.** Installed in the project's `.claude/`, the agents this
  skill uses go by the names written here (`task-implementer`). Installed
  as the `agentic-sdlc` plugin, each one is registered as
  `agentic-sdlc:<name>` (`agentic-sdlc:task-implementer`). Use whichever
  form your agent list shows.

Prerequisite: Phase 2 must be complete and gated (`design/system-design.md`
exists and was approved). If it isn't, tell the user to run `/tech-design`
first.

## Resolving a component

Every task you dispatch has a `component` field (for `single-repo`, the
implicit single component — skip this resolution step entirely). Before
dispatching anything for a task, look up that component's `location` in
`CLAUDE.md`'s Components table, confirm it exists on disk, and pass the
resolved path to the subagent so it reads/writes/runs commands there — not
in `{{HUB_REPO}}`, which only holds the feature's artefacts. Also read that
component's own `CLAUDE.md` for its `{{TEST_CMD}}`, `{{LINT_CMD}}`,
`{{SCHEMA_CHECK_CMD}}`, and `{{MAIN_BRANCH}}` — these are per-component, not
inherited from the hub.

Run every git command for a component as `git -C <resolved path> ...`
(branch check, commit, SHA lookup), so it can't land in the hub's repo by
mistake. In multi-repo, if reading or editing a component is refused
because its directory isn't one Claude Code has access to, stop and ask
the user to add it (see `CLAUDE.md`, "Multi-repo needs directory access")
instead of finding a way around the refusal.

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
   reads spec, acceptance scenarios, and all design artefacts (including
   `design/contracts/*.md`, if any), scans every touched component's
   codebase, and writes `plan.md` (ordered tasks + coverage map) and an
   initialized `progress.md`. Each task carries a `component` field; for
   monorepo/multi-repo, ordering is a topological sort of the Components
   table's `depends-on` graph, modified by contract-first planning — a task
   marked `parallel-ok` can run alongside its dependency's own tasks rather
   than strictly after them (see `CLAUDE.md`'s "Cross-component work" and
   "Layering rule" sections).
2. Check the plan yourself before showing it to anyone:
   - **Coverage**: every acceptance scenario has at least one task, or an
     explicit, reasoned exclusion. For a scenario that spans components,
     confirm each component's slice of it is covered, not just one.
   - **Granularity**: tasks are sliced by related functionality and
     touched files (see `implementation-planner`). If most tasks touch one
     or two files, a task has no observable behaviour of its own, or
     several tasks in a component edit the same file without a stated
     reason, the plan is too granular.
   - **Context**: every task has a `context` entry, and the headings it
     cites exist in the design files. Build agents read only what
     `context` cites, so a missing or wrong citation means an implementer
     works without the design it needed.

   If any check fails, send it back to `implementation-planner` with
   the specific problem before showing the plan to the user.
3. **Gate — Senior Dev / orchestrator confirms the plan with the user.**
   Walk through the task list and coverage map — for monorepo/multi-repo,
   group it by component so the human can see the shape of the cross-repo
   work at a glance, including which tasks are `parallel-ok`. Get explicit
   confirmation before writing any code. This gate has no automated loop —
   it's a conversation; iterate on the plan directly with the user as long
   as it takes.
4. **Offer a fresh session for Build.** Once the plan is confirmed,
   everything Build needs is on disk (`plan.md`, `progress.md`, the
   design). Tell the user Build can start in a fresh session (`/clear` or
   a new session, then `/implement build`), so the planning conversation,
   and any `/feature` or `/tech-design` work before it, isn't re-read on
   every Build turn. Build's own orchestration is mechanical (dispatch,
   relay, commit), so a Sonnet session can run it. They can also stop a
   long Build at any point and resume it the same way. If they'd rather
   continue here, carry on.

### `progress.md` format

```markdown
# Progress — <feature-slug>

| Task | Component | Status | Rounds | Commit SHA |
|---|---|---|---|---|
| T1 | service-api | pending | 0 | — |
| T2 | mobile-android | pending | 0 | — |
...

## Log
- <timestamp> — plan confirmed by human
```

(Drop the `Component` column entirely for `single-repo` — it's the original
v1 format.) Status values: `pending`, `in-progress`, `done`, `BLOCKED`.
Update this file after every task transition, not just at the end of Build
— it's the resume mechanism and the human's live view into where the
feature stands, across however many repos it touches.

## Phase 4 — Build

Process tasks from `plan.md` in order, respecting `depends-on` (both the
intra-component task order and, for monorepo/multi-repo, the cross-
component order from Plan). For each task:

1. **Resolve the component** (see above) and confirm its repo/package is
   present on disk.
2. **Branch safety check.** Confirm the current branch in *that
   component's* repo is not its `{{MAIN_BRANCH}}` before doing anything.
   The branch-protection git hooks (installed per component) are the
   backstop, not the only check — catch this yourself first and tell the
   user if you're unexpectedly on a protected branch. Never pass
   `--no-verify` to get past a hook.
   For a feature touching several components, each one needs its own
   feature branch (naming them consistently, e.g. the same
   `<feature-slug>`, is good practice but not enforced by this skill).
3. Mark the task `in-progress` in `progress.md`.
4. Dispatch a fresh `task-implementer`, scoped to the resolved component
   path, with the task id, its `context` entry from `plan.md`, and the
   component's resolved `{{TEST_CMD}}`, `{{LINT_CMD}}` and
   `{{SCHEMA_CHECK_CMD}}`. It reads only what `context` cites, not the
   whole feature folder. Start a
   fresh implementer and reviewer for every task; never carry one over
   from the previous task, since its context belongs to that task. For
   each `done-when` condition in turn it writes the failing test, confirms
   RED for the right reason, and writes minimal code to GREEN; then it runs
   the full suite plus lint plus schema-check — all using that component's
   own commands. If the task is `parallel-ok` (planned
   against a contract rather than a live dependency), remind it to
   implement against `design/contracts/<contract-name>.md` and, if the
   plan calls for one, to leave the trailing integration task that swaps a
   mock for the real dependency once it's available rather than wiring
   straight to a dependency that may not exist yet.
5. Dispatch a fresh `task-reviewer` (independent context, same component
   scope, same task id, `context` and commands) against the result. It re-runs
   everything itself and returns PASS or FAIL with specifics.
6. **PASS** → commit (one commit per task, in the task's own component
   repo, message referencing the task id), record the commit SHA and
   `status: done` in `progress.md`, move to the next task.
   **FAIL** → increment the task's round counter and send the reviewer's
   findings, verbatim, to the **same** `task-implementer` as a follow-up
   message (SendMessage, or however your tools continue a running agent).
   It still has the task and design in context, so it doesn't re-read
   them. Then send its new report to the **same** `task-reviewer` the same
   way, and go back to the PASS/FAIL decision. Continuing the reviewer
   doesn't weaken its independence, which comes from being separate from
   the implementer. If your tools can't continue a running agent,
   dispatch fresh ones with the task id, `context`, the findings and the
   round number; that works because `plan.md` and the code are on disk.
   This is the **per-task fix loop, capped at 5 rounds** (`CLAUDE.md`).
   **Escalation, round 3** → a continued agent keeps its model, so for
   fix round 3 dispatch a fresh `task-implementer` with the model set to
   `opus`, passing the task id, `context`, the latest findings and the
   round number. Continue that one for rounds 4-5. The reviewer stays as
   it is.
   **Cap hit (round 5, still FAIL)** → mark the task `BLOCKED` in
   `progress.md` with the last reviewer findings attached, **halt Build for
   that component's remaining tasks and anything depending on it**, and
   report to the user. Tasks in an unrelated, non-dependent component may
   continue — report both states clearly (what's blocked, what's still
   proceeding) rather than treating the whole feature as uniformly stuck
   when only one branch of the dependency graph actually is.

### Fewer turns per task

Each of your turns re-reads your whole context, so in a long Build the
number of turns you take per task costs more than anything you say in
them. Keep the bookkeeping to as few turns as you can:
- Do the branch check, `git add` of the task's files, the commit and the
  SHA lookup in **one** shell command (`git -C <path> ...` chained), not
  one turn each.
- Make independent calls in the same message: update `progress.md` for
  the finished task (`done`, SHA) and mark the next one `in-progress` in
  one edit, sent alongside the next task's `task-implementer` dispatch.
- Don't read `progress.md` back after editing it, or re-read `plan.md`
  between tasks; you read it once when Build starts.

A Build left alone runs one task after another in the same session, and
each finished task makes every later turn a little more expensive. When
Build starts with more than about eight tasks left, tell the user once
that they can stop at any point and resume in a fresh session
(`/implement build`) at no cost to the work, since `progress.md` carries
it. A component boundary is a natural place to do it. Then carry on;
don't pause Build to ask.

### Resume

If `/implement build` (or bare `/implement`) is invoked and `progress.md`
already has tasks marked `done`, verify each recorded commit SHA is still
present in its component's branch history (`git log` / `git show`, run
inside that component's repo) before trusting it — don't just trust the
file if a branch has been rebased or amended out from under it. Continue
from the first `pending` or `in-progress` task per the plan's order. A task
left `in-progress` from an interrupted run should be treated as not yet
reviewed — re-run step 5 onward for it rather than assuming partial credit.

## Phase 5 — Review

Runs once every task in `progress.md` is `done`. If Build ran in this
session, offer a fresh one for Review first (`/clear` or a new session,
then `/implement review`), for the same reason as after the plan gate:
Review needs `progress.md`, the feature folder and the code, none of
Build's conversation.

**You are the only writer of `review-report.md`.** Every review agent
below is read-only: it returns its findings in its final message, and you
copy them into the report under the right component's section (or the
Integration review section) without softening or dropping anything.
Keeping one writer means reviews of different components can run side by
side without overwriting each other. When a finding is fixed and
re-verified, update its entry rather than deleting it, so the report shows
what was found and how it was closed.

**Layer 1** (per-task review) is already satisfied by Build — nothing to do
here.

**Layer 2 — feature-wide, per component.** For each component touched,
dispatch `feature-reviewer` scoped to it. These can run in parallel. Each
re-runs that component's full suite itself, checks its slice of acceptance
coverage, design/UX fidelity, and a senior-bar security pass, and returns
its section of the report.

**Layer 2.5 — cross-component integration (monorepo / multi-repo,
cross-component features only).** Dispatch `contract-reviewer` once per
contract in `design/contracts/*.md`. For each, it checks the producing
component's actual implementation against what the contract promised, and
the consuming component's actual implementation against what the contract
let it assume — catching drift between what was agreed at design time and
what either side actually built (a renamed field, a changed status code, a
dropped parameter). It returns entries for the **Integration review**
section of `review-report.md`. Skip this layer entirely for
single-component features.

**Layer 3 — architectural (optional).** For **major**-size features (per
the Phase 2 triage recorded in `design/system-design.md`), or if the user
opts in for a lower-size one, dispatch `architecture-reviewer` per
component against that component's full `git diff {{MAIN_BRANCH}}...HEAD`.
Skip it otherwise — don't run it by default on trivial/moderate changes.

**Layer 4 — external.** If there are external review comments (PR comments
on `{{VCS_HOST}}`, `{{ISSUE_TRACKER}}` comments, anything a human relays),
dispatch `external-review-handler` per finding, resolved to the correct
component before agreeing to act on any of them — an external comment
rarely says which repo it's about.

**Fix loop.** Any blocking finding from layers 2-4 routes back to
`task-implementer` (scoped to the relevant component and files) and then
back to the layer that raised it, for re-verification. As in Build,
continue agents instead of re-dispatching them: keep one implementer per
component across its review fix rounds, and send each fix back to the
**same** reviewer that raised the finding, as a follow-up message saying
what changed, so it doesn't re-read the whole feature folder. Same
fallback if your tools can't continue an agent, and the same round-3
escalation to an `opus` implementer, counted on that component's review
counter. All of layers 2-4
together share the **final review fix loop, capped at 5 rounds per
component, plus one shared counter for layer 2.5** (`CLAUDE.md`) — track
counters per component, not one global counter, so a cap hit in one
component's review doesn't falsely read as a cap hit everywhere.

**Cap hit, still blocking findings** → **hard stop** for the affected
component (and anything depending on it via a contract). Report the
unresolved findings plainly; this is not a state to push a PR out of —
report which components are still clear to proceed and which aren't.

**Layer 5 — the human.** Present `review-report.md` to the user acting as
Senior Dev — **one conversation**, even if it has a section per component
plus an integration section: suite status per component, blocking findings
(should be zero to reach this point), advisories, full acceptance-coverage
table (including cross-component scenarios). Ask them to run the app(s)
themselves and look for what no agent thought to flag — this is not a
rubber-stamp step, and for a cross-component feature it's the one place a
human can sanity-check the full user-visible journey, not just one repo's
slice of it. **Gate: the Senior Dev is the final approver.** Exit requires
zero blocking findings across every component and the integration layer,
every component's suite green, every scenario green, and the human's
explicit sign-off.

## After the gate

Once the human approves, you may open a PR (using whatever VCS tooling is
available) per component touched — for multi-repo this means one PR per
repo, each summarizing its slice of the feature and linking back to the
shared feature folder in `{{HUB_REPO}}` so a reviewer in any one repo can
see the full cross-repo picture. Do **not** merge any of them — merging is
Phase 6, manual, human-only, and backstopped by each component's branch-
protection hook. Point the user at
the project's `docs/PHASE-6-CHECKLIST.md` (copied in at setup) for what
comes next, including the staggered-rollout notes for components with
slower release cadences (mobile app store review, browser-extension store
review).
