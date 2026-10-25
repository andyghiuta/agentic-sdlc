#!/bin/sh
# Agentic SDLC — branch-protection pre-push hook.
#
# Companion to pre-commit-branch-protection.sh. The pre-commit hook stops
# commits made on a protected branch, but not a local merge or fast-forward
# onto it followed by a push. This hook refuses any push whose target is a
# protected branch, so the only way in is a PR merged on the VCS host.
#
# Install: copy to .git/hooks/pre-push and make it executable, or call it
# from your hook manager. See README.md's Install section.

# Keep this list identical to the one in pre-commit-branch-protection.sh.
PROTECTED_BRANCHES="main master"

# Git feeds one line per ref being pushed:
#   <local ref> <local sha> <remote ref> <remote sha>
while read -r local_ref local_sha remote_ref remote_sha; do
  branch=${remote_ref#refs/heads/}

  # Not a branch (a tag, for example) — nothing to protect.
  if [ "$branch" = "$remote_ref" ]; then
    continue
  fi

  for protected in $PROTECTED_BRANCHES; do
    case "$branch" in
      $protected)
        echo "" >&2
        echo "PUSH BLOCKED: '$branch' is a protected branch." >&2
        echo "" >&2
        echo "The agentic SDLC lands work on $branch only through a reviewed" >&2
        echo "PR merged by a human on the VCS host — never a direct push." >&2
        echo "" >&2
        echo "Push your feature branch and open a PR instead:" >&2
        echo "    git push -u origin <feature-slug>" >&2
        echo "" >&2
        exit 1
        ;;
    esac
  done
done

exit 0
