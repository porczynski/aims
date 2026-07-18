# AIMS

**AI Multi-agent Sessions** — git-native session management for AI coding agents,
across many machines and many agents.

![status](https://img.shields.io/badge/status-alpha-orange) ![license](https://img.shields.io/badge/license-MIT-blue) ![shell](https://img.shields.io/badge/shell-bash-121011)

AIMS turns each unit of AI work into a **git branch in an isolated worktree**. Sessions can be
**handed off** between machines and **adopted** by any agent — because the source of truth is a
git remote (`origin`), never a machine-to-machine link. No agent needs access to another's computer.

---

## Why

Running AI agents (Claude, Codex, opencode, Gemini) across a laptop and a workstation creates the
same problems every time: work stranded on one machine, two agents clobbering each other, "done"
that never reached the shared repo, and no clean way to pick up someone else's half-finished task.

AIMS solves this the boring, durable way: **plain git**. Branches, worktrees, and a small set of
scripts with guards that make the failure modes loud instead of silent.

## Model

Two layers, deliberately separated:

| Layer | What | Portable? |
|---|---|---|
| **Work** | branch `ai/<session-id>`, worktree, session files, commits | ✅ yes — via `origin` |
| **Agent context** | an agent's live reasoning/transcript | ❌ no — stays local |

You continue a session from **artifacts** (worklog + commits), never from the previous agent's head.
That is what makes it agent-agnostic and machine-agnostic.

The **engine** (this repo) is public and reusable. Your **data repo** (sessions, project state) is
private and yours. The engine operates on `AIMS_HOME` (default `~/.aims`).

## Install

```bash
git clone https://github.com/<you>/aims ~/aims
~/aims/install.sh                 # links `aims` into ~/.local/bin
aims init                         # scaffold your private data repo (~/.aims)
git -C ~/.aims remote add origin <your-private-data-repo>
aims doctor
```

## Quick start

```bash
aims start myproject "fix login bug" claude    # new branch + worktree
cd ~/.aims/.worktrees/<session-id>             # work here
# ... edit, commit ...
aims save                                       # checkpoint: commit whole worktree + push
aims handoff "waiting on CI"                     # hand to another machine (pushes everything)

# on the other machine / another agent:
aims adopt <session-id>                          # take it over from origin
aims publish <session-id>                        # merge to main, register, done
```

## Commands

| Command | Purpose |
|---|---|
| `aims init [dir]` | Scaffold a data repo |
| `aims start <proj> <topic> [agent] [--scope ...]` | Start a session |
| `aims save` | Checkpoint: commit the whole worktree + push |
| `aims handoff [note]` | Hand session to another machine/agent |
| `aims adopt <id> [--remote]` | Take over a session from origin |
| `aims publish <id>` | Merge to main, append registry, delete branch |
| `aims list` | Active sessions with age / scope / STALE flag |
| `aims doctor` | Health-check engine + data repo |

See [`docs/COMMANDS.md`](docs/COMMANDS.md) for each command's guards and behavior,
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the model, and [`docs/AIMS.md`](docs/AIMS.md)
for the full system reference.
For an optional shared large-file store (NFS/SMB/GlusterFS/CephFS/MinIO/RustFS/Ceph RGW), see
[`docs/SHARED-STORE.md`](docs/SHARED-STORE.md).
How AIMS compares to per-tool session resume (Claude/Codex/Gemini/opencode/Aider): [`docs/COMPARISON.md`](docs/COMPARISON.md).

**Documentation language:** English is the official language. Translations live under
[`docs/i18n/`](docs/i18n/).

## Guarantees & guards

- **No silent data loss**: `aims save` stages the *whole* worktree and always pushes when ahead;
  `aims publish` refuses a dirty or unpushed worktree and warns on an empty merge.
- **No two-writer conflict**: `aims adopt` warns if a branch moved recently; `aims handoff` marks
  a session released so adoption elsewhere is known-safe.
- **`main` is protected**: a `pre-push` hook blocks direct pushes; integration only via `aims publish`.
- **No secrets, no external calls**: the engine talks only to your `origin`. See [`SECURITY.md`](SECURITY.md).

## Requirements

`git`, `bash`, `python3`. macOS and Linux.

## License

MIT — see [`LICENSE`](LICENSE).
