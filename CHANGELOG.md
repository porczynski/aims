# Changelog

## 0.5.0 — 2026-07-19
- One-command setup: bootstrap.sh (curl | bash) installs engine, data repo, and wires agent rules.
- New: aims wire-agents / lib/aims-wire-agents — teaches Claude/Codex/opencode/Gemini to understand
  AIMS by writing an AIMS rules block into their config files (idempotent).
- templates/AGENTS.md rewritten as agent onboarding: natural-language intent -> aims command mapping.
- README: user-facing Install (agent + hardware/storage env), comparison table; Quick start/Commands
  reframed as agent reference.

## 0.4.2 — 2026-07-19
- COMPARISON.md: simplified emoji set to ✅ / ⚠️ / ❌ only.

## 0.4.0 — 2026-07-18
- Added docs/COMPARISON.md: AIMS vs. per-tool session resume (Claude Code, Codex CLI, opencode,
  Gemini CLI, Aider) — context layer vs. work layer, cross-machine and cross-tool portability.

## 0.3.0 — 2026-07-18
- Renamed AISHA -> AIMS (AI Multi-agent Sessions). Command, env vars (AIMS_HOME, AIMS_ARTIFACTS,
  AIMS_GIT_NAME/EMAIL), files and docs updated.

## 0.2.0 — 2026-07-18
- All engine code is English-only.
- Added `aims artifacts <id>` and `AIMS_ARTIFACTS` awareness in `doctor` and `adopt`.
- New `docs/SHARED-STORE.md` (NFS/SMB/GlusterFS/CephFS/MinIO/RustFS/Ceph RGW) + `docs/i18n/` structure.

## 0.1.0 — 2026-07-18
- Initial public extraction of the AIMS engine from a private data repo.
- Commands: init, start, save, handoff, adopt, publish, list, doctor.
- Portable `AIMS_HOME` data-repo model; pre-push main guard; secret scanner.
