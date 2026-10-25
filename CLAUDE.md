# Agentic SDLC — project configuration

This file is the single place a team fills in to point the methodology at
their actual stack. Every skill and subagent in `.claude/` reads these
placeholders instead of hard-coding a language, database, issue tracker, or
deploy tool. Fill in the right-hand column once per project; everything else
in this repo is written against the left-hand placeholder names.

## Settings table

| Placeholder | What it is | Example |
|---|---|---|
| `{{STACK}}` | Primary language/framework | TypeScript + Next.js, Python + Django |
| `{{PKG_MANAGER}}` | Dependency/script runner | `npm`, `pnpm`, `poetry`, `go` |
| `{{TEST_CMD}}` | Runs the full automated test suite | `npm test`, `pytest`, `go test ./...` |
| `{{LINT_CMD}}` | Static analysis / style check | `npm run lint`, `ruff check .` |
| `{{SCHEMA_CHECK_CMD}}` | Verifies the data-layer contract is consistent (migrations applied, types generated, test fixtures match real schema, etc.) — a no-op command if the project has no schema | `npm run schema:check` |
| `{{PRIMARY_DATASTORE}}` | What production data lives in | Postgres, DynamoDB, a third-party API |
| `{{TEST_DATASTORE}}` | What tests run against | SQLite, an in-memory fake, a sandbox tenant |
| `{{ISSUE_TRACKER}}` | Where requirements/bugs are tracked | Jira, Linear, GitHub Issues |
| `{{ISSUE_PREFIX}}` | Ticket key prefix, if any | `PROJ-`, `#` |
| `{{VCS_HOST}}` | Where PRs are opened | GitHub, GitLab, Bitbucket |
| `{{DEPLOY_CMD}}` | How an approved change reaches production | `helm upgrade ...`, `fly deploy`, `git push heroku main` |
| `{{MAIN_BRANCH}}` | The protected branch nothing commits to directly | `main`, `master` |
| `{{DOCS_ROOT}}` | Where per-feature artefact folders live | `docs` |

Skills and agents reference these as literal `{{PLACEHOLDER}}` tokens in
their instructions. Before running `/feature` for the first time on a new
project, replace every placeholder above with the real value (or leave a
short inline note like `{{TEST_CMD}} = npm test` right under the table — the
skills read this file, not a separate config format).

## The six phases, three commands

| # | Phase | Command | Gate owner | Key artefacts |
|---|---|---|---|---|
| 1 | Discover | `/feature` | PM / BA | `specs/spec.md`, `acceptance/*.feature` |
| 2 | Design & architecture | `/tech-design` | Senior Dev | `design/system-design.md`, `design/decisions/ADR-*.md`, `design/ux-spec.md` |
| 3 | Plan | `/implement plan` | Senior Dev (orchestrator) | `plan.md`, `progress.md` |
| 4 | Build | `/implement build` | Orchestrator | code + tests, one commit per task |
| 5 | Review | `/implement review` | Senior Dev | `review-report.md` |
| 6 | Ship & learn | manual (see [docs/PHASE-6-CHECKLIST.md](docs/PHASE-6-CHECKLIST.md)) | Product Owner | merged PR, harness edit |

`/implement` with no argument resumes from wherever `progress.md` says the
feature currently stands, running Plan → Build → Review in order.

Full phase-by-phase detail lives in the skills themselves:
[.claude/skills/feature/SKILL.md](.claude/skills/feature/SKILL.md),
[.claude/skills/tech-design/SKILL.md](.claude/skills/tech-design/SKILL.md),
[.claude/skills/implement/SKILL.md](.claude/skills/implement/SKILL.md).

## Roles

These are human roles, not agents. A gate is not satisfied until the named
human says so in the conversation — an agent reporting "looks good" never
substitutes for it.

- **PM / BA** — owns Phase 1's exit: the spec and acceptance scenarios say
  what the team is actually building.
- **Senior Dev** — owns the Phase 2 design gate and the Phase 5 review gate;
  also acts as the **Orchestrator** driving `/implement` through Phases 3–4
  (confirms the plan, watches the build, never writes code by hand during
  this phase).
- **Product Owner** — owns the Phase 6 gate: did the shipped change deliver
  the value it promised.

## Artefact layout

Every feature gets one folder under `{{DOCS_ROOT}}/<feature-slug>/`:

```
{{DOCS_ROOT}}/<feature-slug>/
  specs/
    spec.md                  # Phase 1
  acceptance/
    *.feature                # Phase 1 — Gherkin, one file per area
  design/
    system-design.md         # Phase 2
    decisions/
      ADR-001-*.md           # Phase 2 — one per genuine trade-off, zero if none
    ux-spec.md                # Phase 2 — only if the change touches UI
    mockups/                  # Phase 2 — HTML mockups, only if the change touches UI
  plan.md                     # Phase 3
  progress.md                 # Phase 3–4, live, resumable
  review-report.md            # Phase 5
```

Nothing outside this folder is "the spec." If a claim about requirements or
design isn't written here, it didn't happen.

## Difficulty triage

`/tech-design` opens by classifying the change as **trivial**, **moderate**,
or **major**, says so out loud, and lets the human override it. The class
decides which artefacts the change actually earns:

- **Trivial** — a short Design section in `system-design.md` only. No ADRs
  (there's no real fork in the road). No `ux-spec.md`/`mockups/` unless the
  change touches UI.
- **Moderate** — full `system-design.md`; an ADR for each real trade-off
  (zero is a valid outcome); `ux-spec.md` + mockups if UI is touched.
- **Major** — the above, plus an explicit risk/rollout section in
  `system-design.md` and an architectural review (`review-pr` layer) during
  Phase 5.

Never produce an artefact the change didn't earn — an ADR with no real
decision in it, or a mockup for a change with no UI, is noise that erodes
trust in the rest of the trail.

## Layering rule (Phase 3 planning)

Default task ordering for `/implement plan`: **schema → service → api →
client**. Each task is a thin vertical slice that one test can pin down —
many small tasks beat a few large ones. If `{{STACK}}` doesn't have these
four layers, replace this rule with the equivalent ordering for your
architecture (e.g. for an event-driven system: schema → producer → consumer
→ client) and note the substitution here so `/implement` picks it up.

## Loop caps (failsafes)

Every validate-and-fix loop in this methodology has a hard round limit.
Hitting the limit is a **hard stop** — the running skill halts, marks the
blocking state explicitly in the relevant artefact (`progress.md` or
`review-report.md`), and surfaces it to the human. It never silently retries
past the cap or ships with the issue unresolved.

| Loop | Cap | Where |
|---|---|---|
| validate-and-fix | ≤ 3 rounds | `/feature` (`validate-spec`), `/tech-design` (`validate-design`) |
| per-task fix loop | ≤ 5 rounds | `/implement build`, one counter per task |
| final review fix loop | ≤ 5 rounds | `/implement review` |

## Branch protection

A git hook (installed per the [README](README.md#install)) physically
refuses commits made directly on `{{MAIN_BRANCH}}`. This is a backstop, not
the only safeguard — the Build phase orchestrator also checks the current
branch before every commit. The only way code reaches `{{MAIN_BRANCH}}` is a
human merging an approved PR (Phase 6).

## Evidence over claims

No skill or agent in this repo accepts "it works," "looks good," or "should
be fine" as a finding. A test that failed for the right reason and now
passes is evidence. A claim re-checked against the actual file/line it
describes is evidence. Anything else gets re-verified before it's trusted —
this applies to agents checking each other's work exactly as much as it
applies to an agent checking a human's requirement.
