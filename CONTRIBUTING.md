# Contributing to AIMS

- Scripts are POSIX-ish bash; keep them portable (macOS BSD + GNU/Linux).
- No private data: no hardcoded hosts, IPs, usernames, emails, or org names.
- `bash -n lib/*` must pass; test changes against a throwaway `AIMS_HOME`.
- Keep the engine free of secrets and of any non-git network calls.
- One logical change per PR; update `docs/` and `CHANGELOG.md`.
