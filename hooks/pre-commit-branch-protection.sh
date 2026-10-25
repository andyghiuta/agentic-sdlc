#!/bin/sh
# Agentic SDLC — branch-protection pre-commit hook.
#
# Physically blocks `git commit` on a protected branch, so the only way
# code reaches it is a human merging an approved PR (Phase 6). This is a
# backstop: the /implement skill's orchestrator also checks the branch
# itself before every task commit during Build, but a hook catches manual
# commits too (from a human, or from any tool that bypasses the skill).
#
# Install: copy this file to .git/hooks/pre-commit in the target project
# and make it executable. See README.md's Install section for the one-line
# version.

# Edit this list to match {{MAIN_BRANCH}} from your project's CLAUDE.md.
# Space-separated; add a release-branch pattern here too if your project
# protects more than one branch (e.g. "main master release/*").
PROTECTED_BRANCHES="main master"

current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

# Not on a branch (detached HEAD, rebase in progress, etc.) — nothing to
# protect against here, let other git machinery handle that state.
if [ -z "$current_branch" ]; then
  exit 0
fi

for protected in $PROTECTED_BRANCHES; do
  case "$current_branch" in
    $protected)
      echo ""
      echo "COMMIT BLOCKED: '$current_branch' is a protected branch." >&2
      echo "" >&2
      echo "The agentic SDLC requires all work to land via a reviewed PR" >&2
      echo "(Phase 5 gate) merged by a human (Phase 6) — never a direct" >&2
      echo "commit to $current_branch." >&2
      echo "" >&2
      echo "Create a feature branch instead:" >&2
      echo "    git checkout -b <feature-slug>" >&2
      echo ""
      exit 1
      ;;
  esac
done

exit 0
