# Agentic SDLC — project configuration

This file is the single place a team fills in to point the methodology at
their actual stack and topology. Every skill and subagent in `.claude/`
reads these placeholders instead of hard-coding a language, database, issue
tracker, deploy tool, or repo layout. Fill in the **Value** column (the
right-hand one) once per project, and once per component where noted;
everything else in this repo is written against the left-hand placeholder
names.

**How a placeholder resolves.** When a skill or agent says `{{TEST_CMD}}`,
it means the Value in the `{{TEST_CMD}}` row of the relevant settings table
— this file for a `single-repo` project, or the component's own
`CLAUDE.md` for monorepo/multi-repo. Keep the placeholder names in the
left column exactly as they are; they're what gets looked up. An empty
Value means "not configured": stop and ask the human for it rather than
guessing from the Example column.

## Repo mode

| Placeholder | What it is | Allowed values | Value |
|---|---|---|---|
| `{{REPO_MODE}}` | How this codebase is laid out | `single-repo` (one repo, one codebase: the plain v1 methodology, nothing under "Components" applies), `monorepo` (one repo, multiple packages/apps), `multi-repo` (one repo per component, checked out as siblings on disk) | `single-repo` |

If `{{REPO_MODE}} = single-repo`, skip straight to "Settings table" below —
everything in "Components" doesn't apply and every placeholder elsewhere in
this file resolves against the one codebase, exactly as in a plain project.

## Components (monorepo / multi-repo only)

A **component** is one deployable/releasable unit at one architectural
layer: a database/schema package, a REST or GraphQL service, an admin web
app, an end-user web app, a native mobile app, a browser extension, or a
shared library consumed by several of the above. In a monorepo a component
is a package or app directory; in multi-repo it's a whole repo.

### Workspace-level settings

| Placeholder | What it is | Example | Value |
|---|---|---|---|
| `{{WORKSPACE_ROOT}}` | Common parent directory every component repo is checked out under (**multi-repo only** — the convention this methodology assumes is sibling checkouts: `{{WORKSPACE_ROOT}}/service-api`, `{{WORKSPACE_ROOT}}/admin-web`, etc. For monorepo this is just the repo root) | `~/dev/acme/` | |
| `{{HUB_REPO}}` | The one component that holds the feature folder (`{{DOCS_ROOT}}/<feature-slug>/`) for a cross-component feature — usually the component you run `/feature` from, or a dedicated coordination repo | `service-api`, `platform-docs` | |

A feature's artefacts live in exactly one place — `{{HUB_REPO}}` — even
when the work spans five repos. This is what lets a plan, a progress file,
or a review report talk about the whole feature in one place instead of
fragmenting across repos that can't see each other.

### Components table

One row per component. `location` is relative to `{{WORKSPACE_ROOT}}`
(multi-repo) or to the monorepo root (monorepo). `settings` points at that
component's own `CLAUDE.md`, which uses the exact same **Settings table**
format defined later in this file, scoped to that one component — every
component fills in its own `{{TEST_CMD}}`, `{{LINT_CMD}}`,
`{{MAIN_BRANCH}}`, etc. independently, since a mobile app's test command
has nothing to do with the service's.

| Component | Layer | Location | Depends on | Settings |
|---|---|---|---|---|
| `db-schema` | `database` | `../db-schema` | — | `../db-schema/CLAUDE.md` |
| `service-api` | `service` | `../service-api` | `db-schema` | `../service-api/CLAUDE.md` |
| `admin-web` | `web-admin` | `../admin-web` | `service-api` | `../admin-web/CLAUDE.md` |
| `enduser-web` | `web-end-user` | `../enduser-web` | `service-api` | `../enduser-web/CLAUDE.md` |
| `mobile-android` | `android` | `../mobile-android` | `service-api` | `../mobile-android/CLAUDE.md` |
| `mobile-ios` | `ios` | `../mobile-ios` | `service-api` | `../mobile-ios/CLAUDE.md` |
| `browser-ext` | `browser-extension` | `../browser-ext` | `service-api` | `../browser-ext/CLAUDE.md` |

(Replace this example with your actual components — add or remove rows
freely; a `shared-lib` layer is common too, for a published package of
generated types/SDK that several clients depend on.)

Valid `layer` values: `database`, `service`, `web-admin`, `web-end-user`,
`android`, `ios`, `browser-extension`, `shared-lib`, `other`.

`depends-on` lists the components whose **contract** (see below) this one
consumes. Every skill in this repo reads this column to order cross-
component work and to decide what a component can safely build against
before its dependency has actually shipped. A component repo that isn't
present on disk where `location` says it should be is a hard stop for any
skill that needs to touch it — say so and ask the human to clone it, never
skip the component silently.

If `depends-on` describes a cycle (A depends on B depends on A), that's a
design smell this methodology refuses to route around automatically — flag
it to the human during `/tech-design` rather than guessing an order.

**Multi-repo needs directory access.** Claude Code works inside the
directory it was started in. Sibling repos are outside it, so reading or
editing them gets a permission prompt or is refused, unless every
component's `location` is listed under `permissions.additionalDirectories`
in the hub's `.claude/settings.json` (see the README's multi-repo install
steps), or added for one session with `--add-dir`. If an agent is refused
access to a component, stop and ask the human to add the directory; don't
work around it. Git commands against a component run as
`git -C <location> ...`, so they always hit that component's repo and
never the hub's by accident.

## Settings table

Lives in `CLAUDE.md` at the project root for a `single-repo` project, or in
each component's own `CLAUDE.md` for `monorepo`/`multi-repo` (pointed to by
that row's `settings` column above).

| Placeholder | What it is | Example | Value |
|---|---|---|---|
| `{{STACK}}` | Primary language/framework | TypeScript + Next.js, Kotlin + Jetpack Compose, Swift + SwiftUI, Python + Django | |
| `{{PKG_MANAGER}}` | Dependency/script runner | `npm`, `pnpm`, `poetry`, `go`, `gradle`, `swift package` | |
| `{{TEST_CMD}}` | Runs the full automated test suite | `npm test`, `pytest`, `./gradlew test`, `xcodebuild test` | |
| `{{LINT_CMD}}` | Static analysis / style check | `npm run lint`, `ruff check .`, `./gradlew ktlintCheck`, `swiftlint` | |
| `{{SCHEMA_CHECK_CMD}}` | Verifies the data-layer contract is consistent (migrations applied, types generated, test fixtures match real schema, etc.) — a no-op command for a component with no schema of its own (most clients) | `npm run schema:check` | |
| `{{PRIMARY_DATASTORE}}` | What production data lives in (database/service components) | Postgres, DynamoDB, a third-party API | |
| `{{TEST_DATASTORE}}` | What tests run against (database/service components) | SQLite, an in-memory fake, a sandbox tenant | |
| `{{ISSUE_TRACKER}}` | Where requirements/bugs are tracked | Jira, Linear, GitHub Issues | |
| `{{ISSUE_PREFIX}}` | Ticket key prefix, if any | `PROJ-`, `#` | |
| `{{VCS_HOST}}` | Where PRs are opened | GitHub, GitLab, Bitbucket | |
| `{{DEPLOY_CMD}}` | How an approved change reaches users — a server deploy for service/web components, a store submission command/process for mobile/extensions | `helm upgrade ...`, `fly deploy`, `fastlane android deploy`, `fastlane ios release`, `web-ext sign && submit` | |
| `{{MAIN_BRANCH}}` | The protected branch nothing commits to directly | `main`, `master` | |
| `{{DOCS_ROOT}}` | Where per-feature artefact folders live. In `monorepo`/`multi-repo`, this only needs a value in `{{HUB_REPO}}`'s own `CLAUDE.md` — other components don't need their own `{{DOCS_ROOT}}` | `docs` | |

Fill in every Value before running `/feature` for the first time on a new
project (or a new component). For monorepo/multi-repo, each component's own
copy of this table lives in a small file made from
[templates/component-CLAUDE.md](templates/component-CLAUDE.md), not a copy
of this whole file.

## The six phases, three commands

| # | Phase | Command | Gate owner | Key artefacts |
|---|---|---|---|---|
| 1 | Discover | `/feature` | PM / BA | `specs/spec.md`, `acceptance/*.feature` |
| 2 | Design & architecture | `/tech-design` | Senior Dev | `design/system-design.md`, `design/decisions/ADR-*.md`, `design/contracts/*.md`, `design/ux-spec.md` |
| 3 | Plan | `/implement plan` | Senior Dev (orchestrator) | `plan.md`, `progress.md` |
| 4 | Build | `/implement build` | Orchestrator | code + tests, one commit per task, in the right component's repo |
| 5 | Review | `/implement review` | Senior Dev | `review-report.md` |
| 6 | Ship & learn | manual (see [docs/PHASE-6-CHECKLIST.md](docs/PHASE-6-CHECKLIST.md)) | Product Owner | merged PR(s), harness edit |

`/implement` with no argument resumes from wherever `progress.md` says the
feature currently stands, running Plan → Build → Review in order. In
`monorepo`/`multi-repo`, one `/implement` run can drive tasks across every
component the feature touches — see "Cross-component work" below.

Full phase-by-phase detail lives in the skills themselves:
[.claude/skills/feature/SKILL.md](.claude/skills/feature/SKILL.md),
[.claude/skills/tech-design/SKILL.md](.claude/skills/tech-design/SKILL.md),
[.claude/skills/implement/SKILL.md](.claude/skills/implement/SKILL.md).

## Roles

These are human roles, not agents. A gate is not satisfied until the named
human says so in the conversation — an agent reporting "looks good" never
substitutes for it. This holds exactly the same whether a feature touches
one component or seven.

- **PM / BA** — owns Phase 1's exit: the spec and acceptance scenarios say
  what the team is actually building, across every component it touches.
- **Senior Dev** — owns the Phase 2 design gate and the Phase 5 review gate;
  also acts as the **Orchestrator** driving `/implement` through Phases 3–4
  (confirms the plan, watches the build, never writes code by hand during
  this phase, in any component).
- **Product Owner** — owns the Phase 6 gate: did the shipped change deliver
  the value it promised, once every component that needed to ship actually
  has.

## Artefact layout

Every feature gets one folder, living in `{{HUB_REPO}}` for
`monorepo`/`multi-repo` (or just the project root for `single-repo`), under
`{{DOCS_ROOT}}/<feature-slug>/`:

```
{{DOCS_ROOT}}/<feature-slug>/
  specs/
    spec.md                  # Phase 1 — includes a Components touched section
    interview-log.md         # Phase 1 — every interview question and answer, verbatim
  acceptance/
    *.feature                # Phase 1 — Gherkin, one file per area
  design/
    system-design.md         # Phase 2
    decisions/
      ADR-001-*.md           # Phase 2 — one per genuine trade-off, zero if none
    contracts/
      <contract-name>.md     # Phase 2 — one per boundary another component depends on
    ux-spec.md                # Phase 2 — only if the change touches UI
    mockups/                  # Phase 2 — HTML mockups, only if the change touches UI
  plan.md                     # Phase 3 — each task tagged with its component
  progress.md                 # Phase 3–4, live, resumable, tracked per component
  review-report.md            # Phase 5 — one section per component + one integration section
```

Nothing outside this folder is "the spec." If a claim about requirements or
design isn't written here, it didn't happen — this holds across every
component's repo, not just the one you happen to be reading code in.

## Cross-component work (monorepo / multi-repo)

This is the part of the methodology that's new relative to a single-repo
project. Four rules carry all of it:

1. **One feature folder, in `{{HUB_REPO}}`.** Whichever components a
   feature touches, its spec, design, plan, progress, and review report are
   written once, in one place. A component other than `{{HUB_REPO}}` never
   gets its own copy of these artefacts — agents working in it read the
   hub's copy (over the filesystem, since `{{WORKSPACE_ROOT}}` siblings are
   all locally checked out) rather than duplicating it.

2. **Contracts are the unit of cross-component dependency.** When a task in
   one component changes something another component's code depends on
   (an API shape, an event schema, a shared type), that boundary gets a
   `design/contracts/<contract-name>.md` artefact during `/tech-design` —
   the request/response or payload shape, field-by-field, in enough detail
   that a consumer can write code against it without the producer existing
   yet. A component's own internal implementation details never need a
   contract; only what crosses into another component's `depends-on` does.

3. **Dependent components plan and build against the contract, not the
   live dependency.** A task in `mobile-android` that needs a new API field
   doesn't wait for `service-api` to be deployed — it's planned and
   implemented against the contract (using a mock/stub generated from it),
   with a trailing **integration task** to swap the mock for the real,
   shipped dependency once it's available. This is what makes parallel work
   across repos possible instead of strictly serial. A task that can start
   as soon as the contract is settled (not waiting on the producing
   component's code) is marked `parallel-ok` in `plan.md`.

4. **Ordering across components follows the dependency graph; ordering
   within a component follows the layering rule.** See "Layering rule"
   below for how the two combine.

Per-component gates still exist (each component's code gets its own
`task-reviewer` pass and its own `feature-reviewer` pass — see
`.claude/skills/implement/SKILL.md`), but the **Phase 5 human gate is one
conversation**: the Senior Dev reviews the whole feature, across every
component it touched, informed by all of their review sections plus the
cross-component integration check, and signs off once — or doesn't.

## Difficulty triage

`/tech-design` opens by classifying the change on two axes, says so out
loud, and lets the human override either one:

- **Size** — **trivial**, **moderate**, or **major**. Decides which
  artefacts the change earns within each component it touches:
  - **Trivial** — a short Design section in `system-design.md` only. No
    ADRs (there's no real fork in the road). No `ux-spec.md`/`mockups/`
    unless the change touches UI.
  - **Moderate** — full `system-design.md`; an ADR for each real trade-off
    (zero is a valid outcome); `ux-spec.md` + mockups if UI is touched.
  - **Major** — the above, plus an explicit risk/rollout section in
    `system-design.md` and an architectural review (`architecture-reviewer`
    layer) during Phase 5.
- **Topology** — **single-component** or **cross-component** (monorepo /
  multi-repo only; always single-component for `single-repo`). A
  cross-component change **always** earns a `design/contracts/*.md`
  artefact for every boundary it crosses and an integration-review pass
  during Phase 5 (via `contract-reviewer`), regardless of size — a
  one-field API change that three mobile apps depend on carries
  coordination risk a same-sized single-component change doesn't, and the
  artefact set reflects that honestly rather than tracking size alone.

Never produce an artefact the change didn't earn — an ADR with no real
decision in it, a contract for a boundary nothing else depends on, or a
mockup for a change with no UI, is noise that erodes trust in the rest of
the trail.

## Layering rule

**Within one component**, default task ordering for `/implement plan`:
**schema → service → api → client**. The layering rule sets the *order*
work happens in, not the size of a task. A task is one cohesive change,
sliced by related functionality and touched files: everything the
component needs for one observable capability, which may span several
layers. Work with no observable behaviour of its own is folded into the
task that uses it, and changes to the same file stay in the same task. See
[implementation-planner](.claude/agents/implementation-planner.md) for the
merge and split rules. If a component's `{{STACK}}` doesn't have these
four layers, replace this rule with the equivalent ordering for its
architecture (e.g. for an event-driven service: schema → producer →
consumer → client) and note the substitution in that component's own
`CLAUDE.md`.

**Across components** (monorepo / multi-repo), task order is a topological
sort of the Components table's `depends-on` graph, modified by contract-
first planning: a task marked `parallel-ok` (see "Cross-component work")
can run alongside its dependency's own tasks rather than strictly after
them, since it's building against the contract, not the live code. A task
that genuinely needs the live, merged dependency (not just its contract) is
never marked `parallel-ok` and waits its turn.

## Loop caps (failsafes)

Every validate-and-fix loop in this methodology has a hard round limit.
Hitting the limit is a **hard stop** — the running skill halts, marks the
blocking state explicitly in the relevant artefact (`progress.md` or
`review-report.md`), and surfaces it to the human. It never silently retries
past the cap or ships with the issue unresolved. This applies per component
— a cap hit in one component halts that component's progress and is
reported, but doesn't necessarily need to block work already in flight on
an independent (non-dependent) component; the orchestrator reports a halted
component's status alongside whatever else is still proceeding.

| Loop | Cap | Where |
|---|---|---|
| validate-and-fix | ≤ 3 rounds | `/feature` (`validate-spec`), `/tech-design` (`validate-design`, including contract validation) |
| per-task fix loop | ≤ 5 rounds | `/implement build`, one counter per task |
| final review fix loop | ≤ 5 rounds | `/implement review`, one counter per component, plus one shared counter for the cross-component integration check |

## Branch protection

Two git hooks (installed per the [README](README.md#install)) physically
guard a component's `{{MAIN_BRANCH}}`: `pre-commit` refuses commits made
on it, and `pre-push` refuses pushes to it, which closes the gap of a
local merge onto `{{MAIN_BRANCH}}` followed by a push. They're a backstop,
not the only safeguard — the Build phase orchestrator also checks the
current branch before every commit, in whichever component's repo it's
about to commit to. The only way code reaches `{{MAIN_BRANCH}}` is a human
merging an approved PR on `{{VCS_HOST}}` (Phase 6). `--no-verify` skips
both hooks; that's a deliberate human escape hatch, and no skill or agent
ever uses it. In `multi-repo`, install the hooks separately in every
component repo — there is no shared `.git` to hook once. In `monorepo`, one
pair at the repo root covers every package.

## Evidence over claims

No skill or agent in this repo accepts "it works," "looks good," or "should
be fine" as a finding. A test that failed for the right reason and now
passes is evidence. A claim re-checked against the actual file/line it
describes is evidence. Anything else gets re-verified before it's trusted —
this applies to agents checking each other's work exactly as much as it
applies to an agent checking a human's requirement. A contract is no
exception: it's evidence of an agreed shape, not evidence that either side
actually implements it — that's only established once each side's real
code is checked against it, which is exactly `contract-reviewer`'s job.
