# Agent rules (AIMS) — template

Copy into your data repo and extend. These are the portable session rules; add your own project
rules below.

## Session protocol
- Start work with `aims start <project> <topic> <agent>`; work only in the printed worktree.
- Checkpoint with `aims save`. Hand to another machine with `aims handoff` (user-triggered).
- Take over an existing session with `aims adopt <id>` — continue from ARTIFACTS, not from the
  previous agent's context. Analyze the session's `environment` block before coding.
- Close with `aims publish <id>`. Never push to `main` directly.

## Secrets
- Never paste secret VALUES into sessions, commits, or logs — only the variable NAME and location.
- Secrets live in the gitignored `credentials/`, never in git.

## Verify before "done"
- After publish: confirm the change is on `main` (`git show origin/main:<file>`), not just "OK".
