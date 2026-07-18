# AIMS commands

All commands operate on `AIMS_HOME` (default `~/.aims`). Session ids are
`<UTC-timestamp>-<project>-<topic>-<agent>`.

### `aims init [dir]`
Scaffold a data repo: `sessions/work/`, `.worktrees/`, `SESSIONS.md`, gitignored `credentials/`.

### `aims start <project> <topic> [agent] [--scope host:x,repo:y,...]`
Creates branch `ai/<id>` + worktree from `origin/main`, seeds `metadata.json` (incl. empty
`environment` block), pushes the start commit.

### `aims save`  *(run inside a worktree)*
`git add -A` (whole worktree) + commit + **push when the branch is ahead of origin**. Never leaves
work stranded.

### `aims handoff [note]`  *(inside a worktree, user-triggered)*
Guarantees `origin` has the complete session, sets `status=handoff`, does not merge to main. Say it
when you switch machines.

### `aims adopt <session-id> [--remote]`
Fetches from origin, prints an **adoption report** (environment + host probe + recommendation),
creates a worktree from the existing branch, logs the takeover. `--remote` = report only. Refuses a
merged/absent session; warns on a recent (possibly live) writer unless `status=handoff`.

### `aims publish <session-id>`
Merges the branch to `main`, appends a registry row to `SESSIONS.md`, deletes the branch. Refuses a
dirty or unpushed worktree; warns on an empty merge; prints the full session diff.

### `aims artifacts <session-id>`
Prints (and creates) the session's directory in the shared large-file store. Requires
`AIMS_ARTIFACTS` to point at a mounted store — see [SHARED-STORE.md](SHARED-STORE.md). Git keeps
pointers; the store keeps bytes.

### `aims list`
Active `ai/*` branches with age, scope, and a STALE flag (>48h).

### `aims doctor`
Checks git/bash/python3, the data repo, registry, and origin remote.
