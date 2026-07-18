# Translations (i18n)

**English is the official language of AIMS.** The authoritative documentation lives in `docs/`
(`README.md`, `AIMS.md`, `ARCHITECTURE.md`, `COMMANDS.md`, `SHARED-STORE.md`). English is always the
source of truth; translations follow it.

## Structure

Translations go under `docs/i18n/<lang>/`, mirroring the English filenames, where `<lang>` is an
ISO 639-1 code:

```
docs/
├── AIMS.md              # English (authoritative)
├── SHARED-STORE.md
└── i18n/
    ├── README.md         # this file
    ├── pl/               # Polski
    │   └── AIMS.md
    ├── de/               # Deutsch
    └── es/               # Español
```

## Rules for translators

- English changes first; translations catch up. A translation may lag — mark it with the English
  commit it was last synced to (e.g. a `> Synced to: <commit>` line at the top).
- Do not translate command names, flags, env vars, or code blocks — only prose.
- Keep file structure and headings identical to the English source so readers can cross-reference.
- If a translation is missing or stale, tools and readers fall back to English.

## Adding a language

1. `mkdir -p docs/i18n/<lang>`
2. Copy the English file, translate the prose, keep code/commands verbatim.
3. Add a top line: `> Translation of docs/<file>. Authoritative version is English.`
4. Open a PR; link the English source file.
