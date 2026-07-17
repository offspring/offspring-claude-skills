---
name: repo-update-docs
description: Use when documentation (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md) needs updating after code changes such as new endpoints, config fields, build targets, or renamed concepts
allowed-tools: ["Bash(git *)", "Read", "Edit", "Skill"]
---

# Update Docs

Review recent code changes and update only the documentation file that owns that type of content. Never duplicate content across docs.

## When to Activate

- After merging a PR that changed behavior, config, or API contracts
- When a code review points out that docs are out of date
- After adding a new endpoint, config field, or integration

## Routing Rules

| Change type | Target doc |
| ----------- | ---------- |
| New/changed endpoint, integration, data model, config field | `ARCHITECTURE.md` |
| New troubleshooting step, secrets setup change, curl example, release process | `DEVELOPER_GUIDE.md` |
| Changed dev setup, prerequisites, test commands | `README.md` |
| New/changed build target, project structure, convention | `CLAUDE.md` |

## Steps

1. Run `git diff HEAD~5` (or `git diff` for unstaged) to identify what changed
2. Classify each change using the routing table above
3. Update only the owning doc — do not copy the same fact into multiple docs
4. For ARCHITECTURE.md: verify every file path and function name before writing
5. Include example request/response JSON for any API or integration changes
6. Run `repo-verify-docs` after all edits to confirm accuracy

## Rules

- Only document endpoints and fields that are actually used in the code
- Keep README.md concise — link to ARCHITECTURE.md for details, not inline them
- Do not edit generated files
- Do not add content to a doc just because it's related — route it to the correct owner
- **Never delete existing documentation files without asking the user first.** If consolidation would make a file redundant, present the list of files to delete and get explicit approval before removing anything
- Do NOT use line numbers in documentation — reference file paths and symbol names only
- **If a Makefile exists**, document `make` targets as the primary commands (e.g. `make test` not `go test ./...`). The Makefile is the canonical interface — raw tool commands belong only as implementation notes, not as user-facing instructions
