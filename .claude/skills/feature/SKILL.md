---
name: feature
description: Phase 1 (Discover) of the agentic SDLC — interviews a new feature into existence, validates the resulting spec against the real codebase, and writes Gherkin acceptance tests. Use when the user wants to start a new feature, invokes /feature, or hands you a messy, informal feature request that needs turning into a proper spec before any design or code happens.
---

# /feature — Discover

You are the orchestrator for Phase 1 of the agentic SDLC (see
[`CLAUDE.md`](../../../CLAUDE.md) for settings placeholders, roles, and the
artefact layout this skill writes into). Your job in this skill is
coordination, not drafting: the interview, validation, and test-writing
below are each done by a subagent so the work stays checked rather than
self-reported.

Read `CLAUDE.md` first if you haven't this session — you need
`{{DOCS_ROOT}}` and the loop-cap table before starting.

## 0. Set up the feature folder

Ask the user for a short feature slug if they haven't given one (kebab-case,
e.g. `bulk-export`). Create:

```
{{DOCS_ROOT}}/<feature-slug>/specs/
{{DOCS_ROOT}}/<feature-slug>/acceptance/
```

If `specs/spec.md` already exists and looks partial (missing sections, open
questions still unanswered), this is a **resume** — tell the user you're
continuing an interrupted interview rather than starting over.

## 1. Interview

Dispatch the `requirements-interviewer` subagent with the user's raw
request and the feature folder path. It will scan the codebase itself and
run the depth-first interview directly with the user (relay its questions
and the user's answers faithfully — don't paraphrase away detail). It
writes incrementally to `specs/spec.md` so the interview can be interrupted
and resumed.

When the interviewer reports the draft spec complete, move on.

## 2. Validate

Dispatch `spec-validator` against the draft `specs/spec.md`.

- **Zero discrepancies** → go to step 3.
- **Discrepancies found** → send them back to `requirements-interviewer`
  (fix mode: here's what's wrong, correct the spec) and re-validate. This is
  round 1 of the **validate-and-fix loop, capped at 3 rounds** (see
  `CLAUDE.md`).
- **Cap hit (3 rounds, still discrepancies)** → **hard stop.** Do not
  proceed to step 3. Tell the user exactly which claims still don't check
  out and why automated fixing isn't converging — this usually means the
  request itself needs human clarification, not another automated attempt.

## 3. Write acceptance tests

Once validation is clean, dispatch `requirements-interviewer` again (or
handle directly if trivial) to write Gherkin scenarios: one `.feature` file
per area of the spec, under `acceptance/`, in plain business language. Every
scenario must trace to a specific section of `specs/spec.md` — if a
scenario doesn't map cleanly to something the spec says, that's a sign the
spec is incomplete; fix the spec, don't write a scenario for a requirement
that doesn't exist yet in writing.

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
step is `/tech-design` for the same feature slug.

## Failure reporting

If you hit the loop cap in step 2, or the interview surfaces something that
looks like it needs a decision only a human can make (scope ambiguity,
conflicting requirements from different people), stop and say so plainly
rather than picking an interpretation and quietly proceeding.
