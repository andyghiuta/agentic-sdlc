# agentic-sdlc

An open-source implementation of the **agentic SDLC** methodology — a
six-phase software development lifecycle where AI agents handle the volume
work (interviewing, validating, decomposing, test-writing, reviewing) and
humans own every decision, every gate, and every merge — as Claude Code
skills and subagents, for any stack, in a single repo, a monorepo, or
across a microservices-style fleet of repos.

Credit: this project implements a methodology described in a public tech
talk, *"Building software with an agentic SDLC"* (speaker: Adrian Apostol,
Tech Lead @ HEITS.digital). This repo is an independent, from-scratch
implementation written from the talk's publicly presented slides and
general Claude Code knowledge — it is not the speaker's own code.

## What this is

Three slash commands drive six phases, each with a named human gate:

| # | Phase | Command | Gate owner |
|---|---|---|---|
| 1 | Discover | `/feature` | PM / BA |
| 2 | Design & architecture | `/tech-design` | Senior Dev |
| 3 | Plan | `/implement plan` | Senior Dev (orchestrator) |
| 4 | Build | `/implement build` | Orchestrator |
| 5 | Review | `/implement review` | Senior Dev |
| 6 | Ship & learn | manual — [checklist](docs/PHASE-6-CHECKLIST.md) | Product Owner |

Every claim an agent makes gets checked against the real codebase before
it's trusted. Every loop that could run forever (fixing a spec, fixing a
design, fixing a failing task, fixing a review finding) has a hard round
cap — hitting it is a stop, never a silent push-through. The orchestrator
never writes code itself during Build, in any repo; every change goes
through an implementer subagent with an independent reviewer subagent
checking its work before anything is committed.

Full methodology detail lives in [`CLAUDE.md`](CLAUDE.md) (settings,
repo modes, roles, artefact layout, loop caps, layering rule) and in each
skill: [`/feature`](.claude/skills/feature/SKILL.md),
[`/tech-design`](.claude/skills/tech-design/SKILL.md),
[`/implement`](.claude/skills/implement/SKILL.md).

This repo makes **no assumptions** about your language, cloud, database,
issue tracker, or deploy tool — every place one of those matters is a
`{{PLACEHOLDER}}` in a settings table in `CLAUDE.md`.

## One repo, a monorepo, or many repos

Set `{{REPO_MODE}}` in `CLAUDE.md` to pick the shape:

- **`single-repo`** (default) — one codebase. Exactly the flow above, no
  further setup.
- **`monorepo`** — one repo, several packages/apps (a service, an admin
  web app, a mobile app, etc. as sibling directories). Add a **Components**
  table to `CLAUDE.md` naming each package, its layer, and its path.
- **`multi-repo`** — one repo per component (classic microservices:
  separate repos for the database/schema, the REST/GraphQL service, the
  admin web app, the end-user web app, Android, iOS, a browser extension —
  any mix). Component repos are expected checked out as siblings under one
  `{{WORKSPACE_ROOT}}`; the feature's artefacts (spec, design, plan,
  progress, review report) live in one designated `{{HUB_REPO}}` so a
  cross-repo feature still has one place that describes the whole thing.

Either way, each component keeps **its own** `CLAUDE.md` with its own
`{{TEST_CMD}}`, `{{LINT_CMD}}`, `{{MAIN_BRANCH}}`, etc. — a mobile app's
settings have nothing to do with a service's, and this methodology never
assumes they match.

When a component depends on another (per the Components table's
`depends-on` column), `/tech-design` writes a **contract** — the shape of
whatever boundary crosses between them — so dependent components can be
planned and built in parallel against that contract instead of waiting on
a live, deployed dependency. `/implement review` then re-checks both sides
against each other once they're both built, catching drift a contract
alone can't prevent. See `CLAUDE.md`'s "Cross-component work" section for
the full mechanics.

## Install

This is a template repo — copy its contents into a target project (or use
it as the project itself if you're starting fresh).

### Single repo

1. Copy the Claude Code harness into your project:

   ```bash
   cp -r .claude /path/to/your-project/
   cp CLAUDE.md /path/to/your-project/   # or merge into an existing CLAUDE.md
   cp -r docs/PHASE-6-CHECKLIST.md /path/to/your-project/docs/
   ```

2. Fill in the settings table in your project's `CLAUDE.md` — replace
   every `{{PLACEHOLDER}}` with your project's real test command, lint
   command, issue tracker, deploy command, etc. Leave `{{REPO_MODE}}` as
   `single-repo` (or just leave that section out).

3. Install the branch-protection hook:

   ```bash
   cp hooks/pre-commit-branch-protection.sh /path/to/your-project/.git/hooks/pre-commit
   chmod +x /path/to/your-project/.git/hooks/pre-commit
   ```

   Edit the `PROTECTED_BRANCHES` line in the installed hook if your
   `{{MAIN_BRANCH}}` isn't `main` or `master`.

4. In Claude Code, from your project root, run `/feature` to start your
   first feature.

### Monorepo

Same as above, but:

- Copy `.claude/` and `CLAUDE.md` to the monorepo **root**.
- Fill in `{{REPO_MODE}} = monorepo` and the **Components** table in the
  root `CLAUDE.md`, one row per package/app, with `location` relative to
  the repo root.
- Each component package can either point its `settings` column at its own
  local `CLAUDE.md` (for a package with real stack differences — e.g. a
  Kotlin Android module in an otherwise TypeScript monorepo) or, for
  packages that genuinely share the same stack/tooling, inline its
  settings directly in the root `CLAUDE.md`'s Settings table.
- Install the branch-protection hook once, at the monorepo root — it
  covers every package, since there's one `.git`.

### Multi-repo

- Check out every component repo as a sibling directory under one
  `{{WORKSPACE_ROOT}}` (e.g. `~/dev/acme/service-api`,
  `~/dev/acme/admin-web`, `~/dev/acme/mobile-android`, ...).
- Pick one repo as `{{HUB_REPO}}` (any component, or a dedicated
  coordination repo) and copy `.claude/` and `CLAUDE.md` there. Fill in
  `{{REPO_MODE}} = multi-repo`, `{{WORKSPACE_ROOT}}`, `{{HUB_REPO}}`, and
  the Components table (each row's `location` relative to
  `{{WORKSPACE_ROOT}}`).
- Copy a plain single-repo `CLAUDE.md` into **every** component repo
  (including the hub, if it's also a component and not a dedicated docs
  repo) and fill in that component's own settings table. This is the file
  each row's `settings` column points at.
- Install the branch-protection hook **separately in every component
  repo** — there's no shared `.git` to hook once:

  ```bash
  for repo in service-api admin-web enduser-web mobile-android mobile-ios browser-ext; do
    cp hooks/pre-commit-branch-protection.sh "$WORKSPACE_ROOT/$repo/.git/hooks/pre-commit"
    chmod +x "$WORKSPACE_ROOT/$repo/.git/hooks/pre-commit"
  done
  ```

- Run `/feature` from `{{HUB_REPO}}`.

## Usage

```
/feature          # Phase 1 — interview a new feature into a validated spec
                   #   {{HUB_REPO}}/docs/<feature>/specs/spec.md
                   #   {{HUB_REPO}}/docs/<feature>/acceptance/*.feature

/tech-design       # Phase 2 — design, scaled to size AND (monorepo/
                   #   multi-repo) topology: single- vs cross-component
                   #   docs/<feature>/design/system-design.md
                   #   docs/<feature>/design/decisions/ADR-*.md
                   #   docs/<feature>/design/contracts/*.md   (cross-component)
                   #   docs/<feature>/design/ux-spec.md (+ mockups/)

/implement         # Phases 3-5 — plan (tasks tagged per component,
                   #   ordered by each component's own layering rule plus
                   #   the cross-component dependency graph), build (TDD,
                   #   task by task, reviewed before every commit, in the
                   #   right repo), then a layered review including a
                   #   cross-component integration check. Resumable:
                   #   re-run /implement after an interruption and it
                   #   picks up where progress.md left off, per component.
```

Then work through [Phase 6's checklist](docs/PHASE-6-CHECKLIST.md) by hand:
decide rollout order across components, merge, deploy/release each one
(accounting for app-store/extension-store review lead time), validate the
outcome in production, and run a retrospective that edits the harness
itself — so the next feature starts ahead of this one.

## Repo layout

```
CLAUDE.md                          # settings, repo mode, Components table, roles,
                                    #   artefact layout, cross-component rules, loop caps
.claude/
  skills/
    feature/SKILL.md               # /feature
    tech-design/SKILL.md           # /tech-design
    implement/SKILL.md             # /implement
  agents/                          # 11 subagents backing the three skills
hooks/
  pre-commit-branch-protection.sh  # blocks direct commits to a protected branch
                                    #   (install once per component repo)
docs/
  PHASE-6-CHECKLIST.md             # manual Ship & Learn checklist
  <feature-slug>/                  # created per feature as you run the skills,
                                    #   in {{HUB_REPO}} for monorepo/multi-repo
```

## License

MIT — see [LICENSE](LICENSE).
