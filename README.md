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

2. Fill in the **Value** column of the settings table in your project's
   `CLAUDE.md`: your real test command, lint command, issue tracker,
   deploy command, and so on. Leave the placeholder names in the left
   column alone; skills look values up by those names. Leave
   `{{REPO_MODE}}` as `single-repo`.

3. Install the branch-protection hooks (see
   [Branch-protection hooks](#branch-protection-hooks) below).

4. In Claude Code, from your project root, run `/feature` to start your
   first feature.

### Monorepo

Same as above, but:

- Copy `.claude/` and `CLAUDE.md` to the monorepo **root**.
- In the root `CLAUDE.md`, set `{{REPO_MODE}}` to `monorepo` and fill in
  the **Components** table, one row per package/app, with `location`
  relative to the repo root.
- For a package whose stack differs from the root's (say, a Kotlin Android
  module in an otherwise TypeScript monorepo), copy
  [templates/component-CLAUDE.md](templates/component-CLAUDE.md) into the
  package directory, fill it in, and point that row's `settings` column at
  it. Packages that share the root's tooling can point `settings` at the
  root `CLAUDE.md` instead.
- Install the hooks once, at the monorepo root; there's one `.git`, so
  they cover every package.

### Multi-repo

- Check out every component repo as a sibling directory under one
  `{{WORKSPACE_ROOT}}` (e.g. `~/dev/acme/service-api`,
  `~/dev/acme/admin-web`, `~/dev/acme/mobile-android`, ...).
- Pick one repo as `{{HUB_REPO}}` (any component, or a dedicated
  coordination repo) and copy `.claude/` and `CLAUDE.md` there. Set
  `{{REPO_MODE}}` to `multi-repo`, and fill in `{{WORKSPACE_ROOT}}`,
  `{{HUB_REPO}}`, and the Components table (each row's `location` relative
  to `{{WORKSPACE_ROOT}}`). If the hub is also a component, its own
  settings go in that same file's Settings table.
- In **every other** component repo, copy
  [templates/component-CLAUDE.md](templates/component-CLAUDE.md) to the
  repo root as `CLAUDE.md` and fill it in. This is the file each row's
  `settings` column points at. It's deliberately small: just that
  component's settings and an optional layer-order override, with the
  methodology itself staying in the hub.
- Give Claude Code access to the sibling repos. It only works inside the
  directory it was started in, so without this, reading or editing another
  component prompts for permission or is refused. In the hub's
  `.claude/settings.json`, list every other component's location:

  ```json
  {
    "permissions": {
      "additionalDirectories": [
        "../db-schema",
        "../admin-web",
        "../enduser-web",
        "../mobile-android",
        "../mobile-ios",
        "../browser-ext"
      ]
    }
  }
  ```

  For a one-off session, `claude --add-dir ../admin-web` does the same.
- Install the hooks **separately in every component repo**; there's no
  shared `.git` to hook once.
- Run `/feature` from `{{HUB_REPO}}`.

### Branch-protection hooks

Two hooks guard the protected branch: `pre-commit` refuses commits made on
it, and `pre-push` refuses pushes to it (which catches a local merge onto
`main` followed by a push). Install both in every repo that holds a
component: once for single-repo and monorepo, once per repo for
multi-repo.

First check whether the repo already uses a hook manager (husky,
lefthook, pre-commit, ...):

```bash
git -C /path/to/repo config core.hooksPath
```

If that prints nothing, no manager has redirected git's hooks, so copy the
scripts into `.git/hooks`:

```bash
REPO=/path/to/repo
cp hooks/pre-commit-branch-protection.sh "$REPO/.git/hooks/pre-commit"
cp hooks/pre-push-branch-protection.sh "$REPO/.git/hooks/pre-push"
chmod +x "$REPO/.git/hooks/pre-commit" "$REPO/.git/hooks/pre-push"
```

Check first that `.git/hooks/pre-commit` and `.git/hooks/pre-push` don't
already exist, since `cp` overwrites them. If either does, call the script
from inside the existing hook instead.

If `core.hooksPath` prints a path, a hook manager is in charge and
`.git/hooks` is ignored. Copy the two scripts somewhere in the repo and
call them from the manager's `pre-commit` and `pre-push` hooks. The
pre-push script reads the list of refs being pushed from standard input,
so make sure the manager passes that through.

For multi-repo, once you've run those checks for every component and
found no hook manager and no existing hooks, loop over the components
(adjust the list to yours):

```bash
for repo in db-schema service-api admin-web enduser-web mobile-android mobile-ios browser-ext; do
  cp hooks/pre-commit-branch-protection.sh "$WORKSPACE_ROOT/$repo/.git/hooks/pre-commit"
  cp hooks/pre-push-branch-protection.sh "$WORKSPACE_ROOT/$repo/.git/hooks/pre-push"
  chmod +x "$WORKSPACE_ROOT/$repo/.git/hooks/pre-commit" "$WORKSPACE_ROOT/$repo/.git/hooks/pre-push"
done
```

Both scripts protect `main` and `master` by default. If your
`{{MAIN_BRANCH}}` is something else, edit the `PROTECTED_BRANCHES` line in
each; keep the two lists the same. `git commit --no-verify` and
`git push --no-verify` skip the hooks. That's there for humans who need it
deliberately; no skill or agent in this repo ever uses it.

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

`/implement` only runs when you type it. Claude won't start it on its own,
because it writes code and makes commits. `/feature` and `/tech-design`
can also be picked up from a plain request like "let's spec out bulk
export".

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
  pre-commit-branch-protection.sh  # blocks commits made on a protected branch
  pre-push-branch-protection.sh    # blocks pushes to a protected branch
templates/
  component-CLAUDE.md              # per-component settings for monorepo/multi-repo
docs/
  PHASE-6-CHECKLIST.md             # manual Ship & Learn checklist
  <feature-slug>/                  # created per feature as you run the skills,
                                    #   in {{HUB_REPO}} for monorepo/multi-repo
```

## License

MIT — see [LICENSE](LICENSE).
