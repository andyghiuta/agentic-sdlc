# agentic-sdlc

An open-source implementation of the **agentic SDLC** methodology — a
six-phase software development lifecycle where AI agents handle the volume
work (interviewing, validating, decomposing, test-writing, reviewing) and
humans own every decision, every gate, and every merge — as Claude Code
skills and subagents, for any stack.

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
never writes code itself during Build; every change goes through an
implementer subagent with an independent reviewer subagent checking its
work before anything is committed.

Full methodology detail lives in [`CLAUDE.md`](CLAUDE.md) (settings,
roles, artefact layout, loop caps, layering rule) and in each skill:
[`/feature`](.claude/skills/feature/SKILL.md),
[`/tech-design`](.claude/skills/tech-design/SKILL.md),
[`/implement`](.claude/skills/implement/SKILL.md).

This repo makes **no assumptions** about your language, cloud, database,
issue tracker, or deploy tool — every place one of those matters is a
`{{PLACEHOLDER}}` in a single settings table in `CLAUDE.md`.

## Install

This is a template repo — copy its contents into a target project (or use
it as the project itself if you're starting fresh).

1. Copy the Claude Code harness into your project:

   ```bash
   cp -r .claude /path/to/your-project/
   cp CLAUDE.md /path/to/your-project/   # or merge into an existing CLAUDE.md
   cp -r docs/PHASE-6-CHECKLIST.md /path/to/your-project/docs/
   ```

2. Fill in the settings table at the top of your project's `CLAUDE.md` —
   replace every `{{PLACEHOLDER}}` with your project's real test command,
   lint command, issue tracker, deploy command, etc.

3. Install the branch-protection hook:

   ```bash
   cp hooks/pre-commit-branch-protection.sh /path/to/your-project/.git/hooks/pre-commit
   chmod +x /path/to/your-project/.git/hooks/pre-commit
   ```

   Edit the `PROTECTED_BRANCHES` line in the installed hook if your
   `{{MAIN_BRANCH}}` isn't `main` or `master`.

4. In Claude Code, from your project root, run `/feature` to start your
   first feature.

## Usage

```
/feature          # Phase 1 — interview a new feature into a validated spec
                   #   docs/<feature>/specs/spec.md
                   #   docs/<feature>/acceptance/*.feature

/tech-design       # Phase 2 — design, scaled to a triaged difficulty
                   #   docs/<feature>/design/system-design.md
                   #   docs/<feature>/design/decisions/ADR-*.md
                   #   docs/<feature>/design/ux-spec.md (+ mockups/)

/implement         # Phases 3-5 — plan, build (TDD, task by task,
                   #   reviewed before every commit), then a five-layer
                   #   feature review. Resumable: re-run /implement after
                   #   an interruption and it picks up where progress.md
                   #   left off.
```

Then work through [Phase 6's checklist](docs/PHASE-6-CHECKLIST.md) by hand:
merge, deploy, validate the outcome in production, and run a retrospective
that edits the harness itself — so the next feature starts ahead of this
one.

## Repo layout

```
CLAUDE.md                          # settings table, roles, artefact layout, loop caps
.claude/
  skills/
    feature/SKILL.md               # /feature
    tech-design/SKILL.md           # /tech-design
    implement/SKILL.md             # /implement
  agents/                          # 10 subagents backing the three skills
hooks/
  pre-commit-branch-protection.sh  # blocks direct commits to the protected branch
docs/
  PHASE-6-CHECKLIST.md             # manual Ship & Learn checklist
  <feature-slug>/                  # created per feature as you run the skills
```

## License

MIT — see [LICENSE](LICENSE).
