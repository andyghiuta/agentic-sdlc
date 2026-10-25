---
name: tech-design
description: Phase 2 (Design & architecture) of the agentic SDLC — triages how hard a validated feature actually is, drafts a system design scaled to that difficulty, and validates it against the real codebase before the Senior Dev gate. Use when the user invokes /tech-design, or wants to move a feature that already has a /feature spec into technical design.
---

# /tech-design — Design & architecture

You are the orchestrator for Phase 2 (see
[`CLAUDE.md`](../../../CLAUDE.md) for settings placeholders, the
difficulty-triage table, and the artefact layout). As in `/feature`,
drafting and checking are each done by a subagent — you coordinate and hold
the gate.

Prerequisite: `{{DOCS_ROOT}}/<feature-slug>/specs/spec.md` and
`acceptance/*.feature` must exist and have passed the Phase 1 gate. If they
don't, tell the user to run `/feature` first.

## 1. Difficulty triage

Before drafting anything, read the spec and scan the codebase yourself for
scope signals: how many files/modules are touched, whether the data model
changes, whether a new external dependency is needed, whether more than one
system/service is involved. Classify the change as **trivial**,
**moderate**, or **major** per `CLAUDE.md`'s difficulty-triage table, and
**announce the read out loud** along with the artefacts it earns, before
proceeding. Give the user a clear chance to override it — a one-line "I'd
call this moderate because X, let me know if you'd read it differently" is
enough; don't block waiting for a response if they don't object.

## 2. Draft the design

Dispatch `architecture-designer` with the feature folder, the spec, the
acceptance scenarios, and the difficulty class. It produces the artefact
set that class earns (see `CLAUDE.md`):
- `design/system-design.md` always.
- `design/decisions/ADR-*.md` only for genuine trade-offs (zero is a valid,
  and for simple changes expected, outcome).
- `design/ux-spec.md` + `design/mockups/` only if the change touches UI.

## 3. Validate

Dispatch `design-validator` against the drafted artefacts.

- **Zero gaps** → go to step 4.
- **Gaps found** → send them back to `architecture-designer` in fix mode,
  re-validate. This is the **validate-and-fix loop, capped at 3 rounds**
  (`CLAUDE.md`).
- **Cap hit, still gaps** → **hard stop.** Report exactly what doesn't
  check out — a design that can't close its own gaps after 3 automated
  rounds usually means the underlying spec is underspecified or the
  approach needs a human rethink, not a 4th automated pass.

## 4. Gate — Senior Dev approval

Present to the user, acting as Senior Dev:
- `system-design.md`, any ADRs, the UX spec/mockups if present.
- Confirmation: zero gaps from `design-validator`.
- The list of open questions and who owns resolving each (a human owner,
  not "TBD").

This is explicitly the phase where the human is expected to **push back and
brainstorm** — the design agent's job was to put something concrete on the
table, not to have the final word. Capture any resulting changes, re-run
`design-validator` if the change is substantive, and only close the gate on
an explicit approval with all open questions resolved or explicitly owned.

## On completion

Tell the user Phase 2 is done, name the artefact paths, and that the next
step is `/implement` (starting with `plan`) for the same feature slug.

## Failure reporting

If triage, drafting, or validation surfaces a decision that's genuinely a
product or cost trade-off rather than a technical correctness question,
stop and hand it to the human explicitly rather than having
`architecture-designer` pick an answer and bury it in the design.
