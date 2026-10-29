# Phase 6 — Ship & Learn (manual checklist)

Phases 1-5 are driven by `/feature`, `/tech-design`, and `/implement`
(or, for a bug or small change, all compressed into `/fix`).
Phase 6 is **not automated** — this is an honest gap, not an oversight:
merging, deploying, and confirming real-world value are consequential
enough that this methodology keeps them a human practice today. Treat this
page as a checklist to run through by hand once a feature's Phase 5 gate
has closed, for every component the feature touched.

**For a `/fix`**, use the same checklist with two substitutions: the PR
links `{{DOCS_ROOT}}/fixes/<fix-slug>.md` instead of a feature folder, and
`/fix`'s Gate 2 sign-off (logged in that file) stands in for the Phase 5
gate and `review-report.md`. "Validate outcome" means the original
reproduction no longer happens in production; a fix has no `.feature`
files. A short retrospective is still worth it when the bug points at a
check the harness should have made.

See [`CLAUDE.md`](../CLAUDE.md) for the `{{PLACEHOLDER}}` settings
referenced below, including `{{REPO_MODE}}` and the Components table. For
`single-repo`, skip straight to "1. Merge & deploy" and ignore every
mention of "per component" — there's only one.

## 0. Decide rollout order (monorepo / multi-repo only)

A cross-component feature rarely ships as one atomic event — read each
touched component's `review-report.md` Integration review section and each
relevant `design/contracts/*.md`'s versioning/compatibility note before
deciding order:

- [ ] For each contract this feature touches, confirm whether it's
      **additive** (producer and consumer can ship independently, in
      either order) or **breaking** (needs the producer live before the
      consumer, or a coordinated simultaneous release).
- [ ] Sequence merges accordingly — generally: `database` → `service` →
      `web-admin`/`web-end-user` → `android`/`ios`/`browser-extension`,
      but a purely additive contract can loosen this; a breaking one makes
      it mandatory.
- [ ] Note explicitly which components are shipping **now** and which are
      shipping **later** (see "Staggered rollout" below) — don't let this
      be implicit.

## 1. Merge & deploy

Repeat this section per component, in the order decided above.

- [ ] Open (or confirm) the PR on `{{VCS_HOST}}` for this component's
      feature branch. It should link the feature folder
      (`{{DOCS_ROOT}}/<feature-slug>/` in `{{HUB_REPO}}`) and, if
      applicable, the `{{ISSUE_TRACKER}}` ticket.
- [ ] Confirm this component's section of `review-report.md` shows zero
      blocking findings and a full green suite — this should already be
      true from the Phase 5 gate, but re-confirm before merging if any
      time has passed (the branch may have moved, or `{{MAIN_BRANCH}}` may
      have changed underneath it).
- [ ] A **human** merges the PR on `{{VCS_HOST}}`. The branch-protection
      hooks installed in this component's own repo block direct commits
      to `{{MAIN_BRANCH}}` (`pre-commit`) and pushes to it (`pre-push`) —
      merging through the PR is the only path in.
- [ ] Deploy/release via this component's own process, from its own
      `CLAUDE.md`: `{{DEPLOY_CMD}}`.
  - **database/service/web-admin/web-end-user** — typically live within
    minutes of merge.
  - **android/ios** — typically a store submission (`fastlane`,
    App Store Connect, Play Console) with review lead time measured in
    hours to days, not minutes. "Merged" is not "live" for these — track
    the submission separately.
  - **browser-extension** — typically a store submission (Chrome Web
    Store, Firefox Add-ons, etc.) with its own review lead time.

### Staggered rollout

It's normal, in multi-repo/monorepo, for some components to be live in
production while others are still pending store review. That's not an
incomplete Phase 6 — it's the expected shape of a cross-component release.
Track each component's actual status (merged / deployed / submitted /
live) until every one that needed to ship has, and don't close this phase
on the assumption that "the PR merged" means "users have this everywhere."

## 2. Validate outcome

- [ ] Run the acceptance journeys from
      `{{DOCS_ROOT}}/<feature-slug>/acceptance/*.feature` against the
      deployed change — not just the automated suite, but a real
      walkthrough in the environment users actually hit. For a
      cross-component journey, this means walking it end to end across
      every component that's actually live — a service-only check doesn't
      validate a journey that finishes on a mobile screen.
- [ ] For components still pending store review, note that outcome
      validation for their slice is deferred, not skipped — come back to
      it once they're live rather than declaring the feature validated on
      partial rollout.
- [ ] Compare the outcome against what `specs/spec.md` said success looks
      like.
- [ ] **Gate — Product Owner accepts the outcome.** This is the final human
      sign-off in the methodology: the PO confirms the promised value was
      actually delivered, not just that code merged cleanly — and, for a
      staggered rollout, confirms whether partial delivery already counts
      as the gate passing or whether it waits for every component.

## 3. Retrospective

- [ ] Ask: what, in hindsight, would have made this feature's pass through
      Phases 1-5 faster, safer, or less friction-prone? A skill that asked
      the wrong kind of question, an agent prompt that missed a check, a
      `CLAUDE.md` setting (workspace-level or per-component) that was wrong
      or missing, a contract that drifted from what got built — anything
      that `/feature`, `/tech-design`, `/implement`, `/fix`, or one of the
      subagents in `.claude/agents/` could do better next time.
- [ ] Produce a concrete output: a PR that edits the harness itself —
      `.claude/skills/*/SKILL.md`, `.claude/agents/*.md`, or `CLAUDE.md`
      (the workspace-level one in `{{HUB_REPO}}`, or a component's own).
      Where that PR goes depends on how the harness is installed:
  - **Copied into the project:** the skill and agent edits go in the
    project's own repo, like any other change.
  - **Installed as the `agentic-sdlc` plugin:** settings edits still go
    in the project's `CLAUDE.md`, but skill and agent edits go to the
    plugin's repo (or your fork of it), and every project picks them up
    on the next plugin update.
- [ ] If nothing needs changing, that's a valid outcome too — but say so
      explicitly rather than skipping the retrospective silently.

**Exit criteria for Phase 6:** success criteria observed in production for
every component that needed to ship (or an explicit, named exception for
one still pending store review), and either a harness-edit PR merged or an
explicit "no harness changes needed" recorded in the feature folder.

## Why this stays manual

Honest status, as of this methodology's v1: automating merge/deploy
approval or production-outcome validation would mean an agent signing off
on something only a human with final accountability should sign off on —
and in multi-repo/monorepo, deciding rollout order and accepting a
staggered release are exactly the kind of judgement calls this methodology
keeps human throughout. This phase is the clearest candidate for future
automation as the methodology matures — but it's deliberately out of scope
here rather than built half-heartedly.
