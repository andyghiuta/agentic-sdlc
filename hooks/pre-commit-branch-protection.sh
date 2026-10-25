#!/bin/sh
# Agentic SDLC — branch-protection pre-commit hook.
#
# Physically blocks `git commit` on a protected branch, so the only way
# code reaches it is a human merging an approved PR (Phase 6). This is a
# backstop: the /implement skill's orchestrator also checks the branch
# itself before every task commit during Build, but a hook catches manual
# commits too (from a human, or from any tool that bypasses the skill).
#
# It doesn't catch a local merge or fast-forward onto a protected branch;
# pre-push-branch-protection.sh covers that by refusing the push.
#
# Install: copy to .git/hooks/pre-commit and make it executable, or call it
# from your hook manager. See README.md's Install section.

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
      echo "" >&2
      echo "COMMIT BLOCKED: '$current_branch' is a protected branch." >&2
      echo "" >&2
      echo "The agentic SDLC requires all work to land via a reviewed PR" >&2
      echo "(Phase 5 gate) merged by a human (Phase 6) — never a direct" >&2
      echo "commit to $current_branch." >&2
      echo "" >&2
      echo "Create a feature branch instead:" >&2
      echo "    git checkout -b <feature-slug>" >&2
      echo "" >&2
      exit 1
      ;;
  esac
done

exit 0
