---
name: repo-verify-docs
description: Use when checking whether documentation (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md) still matches the codebase — after refactors, renames, or endpoint changes, or before a doc-touching PR. Reports only — does not fix.
allowed-tools: ["Bash(grep *)", "Bash(find *)", "Read"]
---

# Verify Docs

Audit all documentation files against the current codebase and report every inaccuracy found. Do NOT make any edits — report only.

## When to Activate

- Before opening a pull request that touches docs
- After a refactor that moves or renames code
- Periodically to catch drift between code and docs
- After running `repo-update-docs` to confirm the update was correct

## What to Check

For each of `ARCHITECTURE.md`, `DEVELOPER_GUIDE.md`, `README.md`, and `CLAUDE.md`:

| Category | What to verify |
| -------- | -------------- |
| File references | Every file path mentioned actually exists |
| Function & type names | Every named symbol exists in the codebase (grep to confirm) |
| Endpoints | HTTP method, path, status codes, and request/response fields match the handler |
| Config keys | Every env var name and default value matches the actual config |
| Build commands | Every build/test command in CLAUDE.md references a target or script that exists (Makefile target, package.json script, etc.) — verify statically, do not execute |
| Mermaid diagrams | Sequence and component diagrams reflect the actual flow in code |
| Cross-doc links | Every `[text](doc.md#anchor)` resolves to a real heading in the target doc |
| Stale terminology | No renamed concepts, packages, or endpoints still using the old name |

## How to Report

Group findings by document. For each issue:

```text
ARCHITECTURE.md
  - references server/handler.go but processRequest function no longer exists there
  - /api/v1/token endpoint listed but code uses /api/v1/exchange
```

## Rules

- Do NOT include line numbers in reports — reference file paths and symbol names only
- Do not fix anything — report only
- **If a Makefile exists**, verify that documented build/test/generate commands reference `make` targets rather than raw tool invocations — flag any that bypass the Makefile
- After reporting, suggest running `repo-update-docs` for any substantive changes
