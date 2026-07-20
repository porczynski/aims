#!/usr/bin/env bash
set -euo pipefail
# AIMS one-command setup. Installs the engine, creates your data repo, and teaches your installed
# agents (Claude Code, Codex, opencode, Gemini CLI) to understand AIMS.
#
#   curl -fsSL https://raw.githubusercontent.com/visaroy/aims/main/bootstrap.sh | bash
#
# Non-interactive (CI / unattended): set AIMS_ACCEPT=1 to accept the terms below up front.
# Overridable via env: AIMS_REPO, AIMS_DIR (engine checkout), AIMS_HOME (data repo).
REPO="${AIMS_REPO:-https://github.com/visaroy/aims}"
DIR="${AIMS_DIR:-$HOME/aims}"
DATA="${AIMS_HOME:-$HOME/.aims}"
say(){ printf '\n== %s\n' "$*"; }

say "0/5 license & consent"
cat <<EOF
AIMS — AI Multi-agent Sessions.   License: MIT — provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
On THIS machine this installer will:
  - clone the engine to $DIR and link the 'aims' command into ~/.local/bin
  - create a local data repo at $DATA (git; no remote until you add one yourself)
  - modify the config files of DETECTED AI agents to teach them AIMS (each original is backed up first)
It makes no network calls except 'git' to repositories you configure. You install and run it at your
own risk; the authors accept no liability. See LICENSE and SECURITY.md in $REPO.
EOF
if [ "${AIMS_ACCEPT:-0}" = 1 ] || [ "${AIMS_ACCEPT:-}" = yes ]; then
  echo "  accepted via AIMS_ACCEPT"
elif ( : </dev/tty ) 2>/dev/null; then   # a real terminal is reachable (works under curl|bash)
  printf 'Type "yes" to accept these terms and continue: ' > /dev/tty; read -r _ans < /dev/tty || _ans=
  [ "$_ans" = yes ] || { echo "Aborted — nothing installed."; exit 1; }
else
  echo "Non-interactive install: re-run with AIMS_ACCEPT=1 to accept the terms above." >&2; exit 1
fi

say "1/5 engine -> $DIR"
if [ -d "$DIR/.git" ]; then git -C "$DIR" pull --ff-only -q && echo "  updated"; else git clone -q "$REPO" "$DIR" && echo "  cloned"; fi

say "2/5 command -> ~/.local/bin/aims"
"$DIR/install.sh" >/dev/null && echo "  linked"
export PATH="$HOME/.local/bin:$PATH"

say "3/5 data repo -> $DATA"
if [ -d "$DATA/.git" ]; then echo "  exists"; else AIMS_HOME="$DATA" "$DIR/lib/aims-init" "$DATA" >/dev/null && echo "  created"; fi
echo "  (add a remote so it syncs across machines:  git -C $DATA remote add origin <url>)"

say "4/5 teach agents to understand AIMS"
AIMS_ROOT="$DIR" AIMS_YES=1 "$DIR/lib/aims-wire-agents"   # consent already given above

say "5/5 done"
echo "Add to your shell profile:  export AIMS_HOME=$DATA"
echo "Verify:                     aims doctor"
echo
echo "You do not need to learn aims commands — just talk to your agent normally"
echo "('save and close the session', 'hand this off to the other machine'); it runs AIMS for you."
