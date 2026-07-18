#!/usr/bin/env bash
set -euo pipefail
# Installs the `aims` command onto PATH by symlinking bin/aims into ~/.local/bin.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/bin"
ln -sf "$root/bin/aims" "$HOME/.local/bin/aims"
echo "✅ linked $HOME/.local/bin/aims -> $root/bin/aims"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "⚠️  add ~/.local/bin to PATH";; esac
echo "Next: aims init && aims doctor"
