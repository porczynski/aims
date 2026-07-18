#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"
fail=0
bad_untracked="$(git ls-files --others --exclude-standard -- '.active/*.json' 2>/dev/null || true)"
if [ -n "$bad_untracked" ]; then printf 'WARN: legacy untracked active markers are ignored by AIMS:\n%s\n' "$bad_untracked" >&2; fi
bad_ids="$(git ls-files --cached -- '.active/s[0-9]*.json' '.active/s[0-9]*-*.json' 2>/dev/null || true)"
if [ -n "$bad_ids" ]; then printf 'WARN: legacy sNNN marker IDs are ignored by AIMS:\n%s\n' "$bad_ids" >&2; fi
if [ -d .active ]; then
  while IFS= read -r marker; do
    [ -z "$marker" ] && continue
    if ! python3 -m json.tool "$marker" >/dev/null 2>&1; then printf 'ERROR: invalid JSON marker: %s\n' "$marker" >&2; fail=1; fi
  done < <(git ls-files --cached -- '.active/*.json' 2>/dev/null || true)
fi
[ "$fail" -eq 0 ] && echo "OK: marker validation passed (AIMS ignores legacy markers)"
exit "$fail"
