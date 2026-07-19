#!/usr/bin/env bash
set -euo pipefail
# AIMS one-command setup. Installs the engine, creates your data repo, and teaches your installed
# agents (Claude Code, Codex, opencode, Gemini CLI) to understand AIMS.
#
#   curl -fsSL https://raw.githubusercontent.com/visaroy/aims/main/bootstrap.sh | bash
#
# Overridable via env: AIMS_REPO, AIMS_DIR (engine checkout), AIMS_HOME (data repo).
REPO="${AIMS_REPO:-https://github.com/visaroy/aims}"
DIR="${AIMS_DIR:-$HOME/aims}"
DATA="${AIMS_HOME:-$HOME/.aims}"
say(){ printf '\n== %s\n' "$*"; }

say "1/4 engine -> $DIR"
if [ -d "$DIR/.git" ]; then git -C "$DIR" pull --ff-only -q && echo "  updated"; else git clone -q "$REPO" "$DIR" && echo "  cloned"; fi

say "2/4 command -> ~/.local/bin/aims"
"$DIR/install.sh" >/dev/null && echo "  linked"
export PATH="$HOME/.local/bin:$PATH"

say "3/4 data repo -> $DATA"
if [ -d "$DATA/.git" ]; then echo "  exists"; else AIMS_HOME="$DATA" "$DIR/lib/aims-init" "$DATA" >/dev/null && echo "  created"; fi
echo "  (add a remote so it syncs across machines:  git -C $DATA remote add origin <url>)"

say "4/4 teach agents to understand AIMS"
AIMS_ROOT="$DIR" "$DIR/lib/aims-wire-agents"

say "done"
echo "Add to your shell profile:  export AIMS_HOME=$DATA"
echo "Verify:                     aims doctor"
echo
echo "You do not need to learn aims commands — just talk to your agent normally"
echo "('save and close the session', 'hand this off to the other machine'); it runs AIMS for you."
