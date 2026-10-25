# Phase 6 — Ship & Learn (manual checklist)

Phases 1-5 are driven by `/feature`, `/tech-design`, and `/implement`.
Phase 6 is **not automated** — this is an honest gap, not an oversight:
merging, deploying, and confirming real-world value are consequential
enough that this methodology keeps them a human practice today. Treat this
page as a checklist to run through by hand once a feature's Phase 5 gate
has closed.

See [`CLAUDE.md`](../CLAUDE.md) for the `{{PLACEHOLDER}}` settings
referenced below.

## 1. Merge & deploy

- [ ] Open (or confirm) the PR on `{{VCS_HOST}}` for the feature branch.
      It should link the feature folder (`{{DOCS_ROOT}}/<feature-slug>/`)
      and, if applicable, the `{{ISSUE_TRACKER}}` ticket.
- [ ] Confirm `review-report.md` shows zero blocking findings and a full
      green suite — this should already be true from the Phase 5 gate, but
      re-confirm before merging if any time has passed (the branch may have
      moved, or `{{MAIN_BRANCH}}` may have changed underneath it).
- [ ] A **human** merges the PR. The branch-protection hook
      (`hooks/pre-commit-branch-protection.sh`) blocks any direct commit to
      `{{MAIN_BRANCH}}` — merging through the PR is the only path in.
- [ ] Deploy via the project's existing rollout process: `{{DEPLOY_CMD}}`.

## 2. Validate outcome

- [ ] Run the acceptance journeys from
      `{{DOCS_ROOT}}/<feature-slug>/acceptance/*.feature` against the
      deployed change — not just the automated suite, but a real
      walkthrough in the environment users actually hit.
- [ ] Compare the outcome against what `specs/spec.md` said success looks
      like.
- [ ] **Gate — Product Owner accepts the outcome.** This is the final human
      sign-off in the methodology: the PO confirms the promised value was
      actually delivered, not just that code merged cleanly.

## 3. Retrospective

- [ ] Ask: what, in hindsight, would have made this feature's pass through
      Phases 1-5 faster, safer, or less friction-prone? A skill that asked
      the wrong kind of question, an agent prompt that missed a check, a
      `CLAUDE.md` setting that was wrong or missing — anything that
      `/feature`, `/tech-design`, `/implement`, or one of the subagents in
      `.claude/agents/` could do better next time.
- [ ] Produce a concrete output: a PR that edits the harness itself —
      `.claude/skills/*/SKILL.md`, `.claude/agents/*.md`, or `CLAUDE.md`.
- [ ] If nothing needs changing, that's a valid outcome too — but say so
      explicitly rather than skipping the retrospective silently.

**Exit criteria for Phase 6:** success criteria observed in production, and
either a harness-edit PR merged or an explicit "no harness changes needed"
recorded in the feature folder.

## Why this stays manual

Honest status, as of this methodology's v1: automating merge/deploy
approval or production-outcome validation would mean an agent signing off
on something only a human with final accountability should sign off on.
This phase is the clearest candidate for future automation as the
methodology matures — but it's deliberately out of scope here rather than
built half-heartedly.
