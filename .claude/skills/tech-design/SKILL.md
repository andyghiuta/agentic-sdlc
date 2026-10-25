---
name: tech-design
description: Phase 2 (Design & architecture) of the agentic SDLC — triages how hard a validated feature actually is (size, and in monorepo/multi-repo, how many components it crosses), drafts a system design — plus cross-component contracts where relevant — scaled to that triage, and validates it all against the real codebase(s) before the Senior Dev gate. Use when the user invokes /tech-design, or wants to move a feature that already has a /feature spec into technical design.
argument-hint: "[feature-slug]"
---

# /tech-design — Design & architecture

You are the orchestrator for Phase 2. As in `/feature`, drafting and
checking are each done by a subagent — you coordinate and hold the gate.

## Before you start

- **Read the project's `CLAUDE.md`**, at the root of the project you're
  working in, if you haven't this session. You need the settings
  placeholders, the difficulty-triage section, and the artefact layout.
  Don't look for it relative to this skill's own folder: when the skill is
  installed as a plugin, the files beside it belong to the plugin, not the
  project. If the project's `CLAUDE.md` is a component settings file (it
  has a **Hub** line), read the hub's `CLAUDE.md` as well; the methodology
  settings, the Components table, and the feature folders live there.
- **Agent names.** Installed in the project's `.claude/`, the agents this
  skill uses go by the names written here (`architecture-designer`).
  Installed as the `agentic-sdlc` plugin, each one is registered as
  `agentic-sdlc:<name>` (`agentic-sdlc:architecture-designer`). Use
  whichever form your agent list shows.

Prerequisite: `{{DOCS_ROOT}}/<feature-slug>/specs/spec.md` and
`acceptance/*.feature` must exist and have passed the Phase 1 gate. If they
don't, tell the user to run `/feature` first.

## 1. Difficulty triage

Before drafting anything, read the spec (including its Components-touched
section, for monorepo/multi-repo) and scan the relevant codebase(s)
yourself for scope signals: how many files/modules are touched, whether the
data model changes, whether a new external dependency is needed. Classify
the change on **two axes** per `CLAUDE.md`'s difficulty-triage section, and
**announce both reads out loud** along with the artefacts they earn — for
example, "I'd call this moderate and cross-component because X, which
earns a full system design, contracts for the two API boundaries, and no
ADRs unless a real trade-off turns up." Then **stop and wait** for the user
to confirm or override. Drafting the design is the expensive step, and
redoing it because the triage was wrong costs far more than one short
question. Record the agreed triage at the top of `system-design.md` so
later phases (and Phase 5's decision about the architectural review) can
read it.

- **Size** — trivial / moderate / major.
- **Topology** — single-component or cross-component (always
  single-component for `single-repo`; read straight off the spec's
  Components-touched section for monorepo/multi-repo — more than one
  component named there means cross-component).

## 2. Draft the design

Dispatch `architecture-designer` with the feature folder, the spec, the
acceptance scenarios, and both triage results. It produces the artefact set
that class earns (see `CLAUDE.md`):
- `design/system-design.md` always — for cross-component features, this
  includes a **Components & contracts** section naming every component
  touched, its role, and which boundaries between them carry a contract.
- `design/decisions/ADR-*.md` only for genuine trade-offs (zero is a valid,
  and for simple changes expected, outcome).
- `design/contracts/<contract-name>.md` for **cross-component** features —
  one per boundary where one touched component's `depends-on` (per the
  Components table) means it consumes something another touched component
  produces. Each contract spells out the request/response or payload shape
  in enough detail that the consuming component's tasks can be planned and
  implemented against it without the producing component's code existing
  yet.
- `design/ux-spec.md` + `design/mockups/` only if the change touches UI
  (any `web-admin`, `web-end-user`, `android`, `ios`, or
  `browser-extension` component counts).

## 3. Validate

Dispatch `design-validator` against the drafted artefacts. For
cross-component features, also dispatch `contract-reviewer` against each
`design/contracts/*.md` — it checks that the contract is actually
implementable by the producing component (the shape it promises is
achievable against that component's real code/schema) and actually
sufficient for the consuming component's acceptance scenarios (nothing the
consumer needs is missing from the contract).

- **Zero gaps** (from both `design-validator` and, where applicable,
  `contract-reviewer`) → go to step 4.
- **Gaps found** → send them back to `architecture-designer` in fix mode,
  re-validate. This is the **validate-and-fix loop, capped at 3 rounds**
  (`CLAUDE.md`) — one shared counter across design and contract gaps, not
  one each.
- **Cap hit, still gaps** → **hard stop.** Report exactly what doesn't
  check out — a design that can't close its own gaps after 3 automated
  rounds usually means the underlying spec is underspecified or the
  approach needs a human rethink, not a 4th automated pass.

## 4. Gate — Senior Dev approval

Present to the user, acting as Senior Dev:
- `system-design.md`, any ADRs, any contracts, the UX spec/mockups if
  present.
- Confirmation: zero gaps from `design-validator` and `contract-reviewer`.
- The list of open questions and who owns resolving each (a human owner,
  not "TBD") — for cross-component features, flag any open question that's
  really "which team/component owns this" as its own item; that's a
  coordination question the design can't resolve on its own.

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
