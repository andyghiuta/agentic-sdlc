---
name: feature
description: Phase 1 (Discover) of the agentic SDLC — interviews a new feature into existence, validates the resulting spec against the real codebase (across every component it touches, in monorepo/multi-repo), and writes Gherkin acceptance tests. Use when the user wants to start a new feature, invokes /feature, or hands you a messy, informal feature request that needs turning into a proper spec before any design or code happens.
argument-hint: "[feature-slug] [request]"
---

# /feature — Discover

You are the orchestrator for Phase 1 of the agentic SDLC. Your job in this
skill is coordination, not drafting: the interview, validation, and
test-writing below are each done by a subagent so the work stays checked
rather than self-reported.

## Before you start

- **Read the project's `CLAUDE.md`**, at the root of the project you're
  working in, if you haven't this session. You need `{{DOCS_ROOT}}`,
  `{{REPO_MODE}}`, the Components table (if present), and the loop-cap
  table. Don't look for it relative to this skill's own folder: when the
  skill is installed as a plugin, the files beside it belong to the
  plugin, not the project. If the project's `CLAUDE.md` is a component
  settings file (it has a **Hub** line), read the hub's `CLAUDE.md` as
  well; the methodology settings, the Components table, and the feature
  folders live there. If you can't find the settings at all, stop and ask
  the user to set the project up first (see the agentic-sdlc README).
- **Agent names.** Installed in the project's `.claude/`, the agents this
  skill uses go by the names written here (`requirements-interviewer`).
  Installed as the `agentic-sdlc` plugin, each one is registered as
  `agentic-sdlc:<name>` (`agentic-sdlc:requirements-interviewer`). Use
  whichever form your agent list shows.

## 0. Set up the feature folder

Ask the user for a short feature slug if they haven't given one (kebab-case,
e.g. `bulk-export`). The folder lives in `{{HUB_REPO}}` for
`monorepo`/`multi-repo` (just the project root for `single-repo`). Create:

```
{{DOCS_ROOT}}/<feature-slug>/specs/
{{DOCS_ROOT}}/<feature-slug>/acceptance/
```

If `specs/spec.md` already exists and looks partial (missing sections, open
questions still unanswered), this is a **resume** — tell the user you're
continuing an interrupted interview rather than starting over.

## 0.5. Identify touched components (monorepo / multi-repo only)

Skip this step entirely for `{{REPO_MODE}} = single-repo`.

From the user's raw request and a quick read of the Components table in
`CLAUDE.md`, name a first-guess list of which components this feature
probably touches (e.g. "sounds like this needs `service-api` and
`enduser-web`"). Say this out loud and let the human correct it before the
interview starts — getting this wrong just means `requirements-interviewer`
scans an unnecessary component or misses one, either of which step 1 can
still surface and fix, but starting with a reasonable guess saves rounds.
For any component in the guess list that isn't present on disk at its
`location`, stop and tell the user before proceeding — don't interview
against a component you can't actually read.

## 1. Interview

A subagent can't stop and wait for the user, so the interview runs in
rounds, with you as the go-between:

1. Dispatch `requirements-interviewer` with the user's raw request, the
   feature folder path, and — for monorepo/multi-repo — the list of
   touched components and their locations from step 0.5. It scans each
   touched component's codebase, then ends its turn with either a
   **QUESTION** or **DONE**.
2. On **QUESTION**, put it to the user word for word — don't paraphrase
   away detail. When it offers a few clear options, a multiple-choice
   prompt is fine; otherwise ask in plain text.
3. Continue the same interviewer with the user's answer, verbatim (send it
   to the running agent if your tools allow that; otherwise dispatch a
   fresh one with the folder path, which works because it keeps
   everything on disk). Repeat from step 2.
4. On **DONE**, move on.

Each round, the interviewer writes `specs/interview-log.md` (every
question and answer, verbatim) and updates `specs/spec.md`, so the
interview can stop at any point and resume later. For monorepo/multi-repo
the spec includes a **Components touched** section listing each
component, its layer, and why the feature needs it.

## 2. Validate

Dispatch `spec-validator` against the draft `specs/spec.md`. For
monorepo/multi-repo, it checks claims against **every** component named in
the spec's Components-touched section, not just one — a claim about
`service-api`'s current behaviour gets checked against `service-api`'s
code, not whichever repo happens to be open.

- **Zero discrepancies** → go to step 3.
- **Discrepancies found** → send them back to `requirements-interviewer`
  (fix mode: here's what's wrong, correct the spec). If it comes back with
  a QUESTION because a correction changes something the user said, relay
  it as in step 1. Then re-validate. This is
  round 1 of the **validate-and-fix loop, capped at 3 rounds** (see
  `CLAUDE.md`).
- **Cap hit (3 rounds, still discrepancies)** → **hard stop.** Do not
  proceed to step 3. Tell the user exactly which claims still don't check
  out and why automated fixing isn't converging — this usually means the
  request itself needs human clarification, not another automated attempt.

## 3. Write acceptance tests

Once validation is clean, dispatch `requirements-interviewer` in acceptance
mode to write Gherkin scenarios: one `.feature` file
per area of the spec, under `acceptance/`, in plain business language. Every
scenario must trace to a specific section of `specs/spec.md` — if a
scenario doesn't map cleanly to something the spec says, that's a sign the
spec is incomplete; fix the spec, don't write a scenario for a requirement
that doesn't exist yet in writing. For monorepo/multi-repo, a scenario that
exercises an end-to-end journey across components (e.g. a mobile action
that depends on a new API field) stays as **one** scenario — don't split a
single user-visible behaviour into one `.feature` file per component just
because the implementation will eventually span repos; `/implement plan`
is what breaks it into per-component tasks later.

## 4. Gate — PM / BA sign-off

Present to the user, acting as PM/BA:
- The final `specs/spec.md`.
- The list of `.feature` files and what each covers.
- Confirmation: zero discrepancies from `spec-validator`, every scenario
  maps to a spec section.

Ask for explicit approval. Do not treat silence, a topic change, or "looks
fine I guess" as a gate pass — get an actual yes, or specific requested
changes (loop back to step 1/2 as needed; changes requested *after* a prior
approval don't count against the validate-and-fix cap, which only covers
automated fix rounds).

## On completion

Tell the user Phase 1 is done, name the artefact paths, and that the next
step is `/tech-design` for the same feature slug. `/tech-design` reads
everything it needs from the feature folder, so suggest running it in a
fresh session (`/clear` or a new session): this conversation would
otherwise be re-read on every turn of the next phase.

## Failure reporting

If you hit the loop cap in step 2, or the interview surfaces something that
looks like it needs a decision only a human can make (scope ambiguity,
conflicting requirements from different people), stop and say so plainly
rather than picking an interpretation and quietly proceeding.
