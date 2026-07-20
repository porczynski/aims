#!/usr/bin/env bash
# One-time contributor setup for the AIMS engine repo — run once per clone/machine.
# Pins an anonymous commit identity so a machine's personal git identity never leaks
# into this public repo, and installs the pre-commit guard that enforces it.
set -euo pipefail
cd "$(dirname "$0")"
git config --local user.name  "The AIMS authors"   # override whatever personal identity this machine has
git config --local user.email "aims@localhost"
hooks_dir="$(git rev-parse --git-common-dir)/hooks"  # common dir = shared across worktrees
install -m 0755 hooks/pre-commit "$hooks_dir/pre-commit"  # copy hook, do NOT set core.hooksPath (would also arm pre-push)
echo "OK: anonymous identity pinned + pre-commit guard installed for $(git rev-parse --show-toplevel)"
