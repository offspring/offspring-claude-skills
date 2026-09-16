---
name: repo-verify-docs
description: Use when checking whether documentation (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md) still matches the codebase — after refactors, renames, or endpoint changes, or before a doc-touching PR. Reports only — does not fix.
allowed-tools: ["Bash(grep *)", "Bash(find *)", "Read"]
model: sonnet
context: fork
agent: Explore
background: false
---

# Verify Docs

Audit `ARCHITECTURE.md`, `DEVELOPER_GUIDE.md`, `README.md`, and `CLAUDE.md` against the code. Report only; edit nothing.

| Check | Verify |
| ----- | ------ |
| File references | Every path exists |
| Symbols | Every function/type name exists (grep) |
| Endpoints | Method, path, status codes, fields match the handler |
| Config keys | Env var names and defaults match the config |
| Build commands | Every command references an existing Makefile target or script — check statically, don't run |
| Makefile | If one exists, documented commands use `make` targets, not raw tools |
| Diagrams | Mermaid flows match the code |
| Cross-doc links | Every `[text](doc.md#anchor)` resolves to a heading |
| Terminology | No renamed concept still uses its old name |

## Report

Group by document, paths and symbol names only, no line numbers:

```text
ARCHITECTURE.md
  - references server/handler.go but processRequest no longer exists there
  - /api/v1/token listed but code uses /api/v1/exchange
```

End by suggesting `repo-update-docs` for substantive findings.
