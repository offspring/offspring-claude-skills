---
name: repo-update-docs
description: Use when documentation (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md) needs updating after code changes such as new endpoints, config fields, build targets, or renamed concepts
allowed-tools: ["Bash(git *)", "Read", "Edit", "Skill"]
---

# Update Docs

Update only the doc that owns each changed fact. Never duplicate a fact across docs.

## Routing

| Change | Doc |
| ------ | --- |
| Endpoint, integration, data model, config field | `ARCHITECTURE.md` |
| Troubleshooting, secrets setup, curl example, release process | `DEVELOPER_GUIDE.md` |
| Dev setup, prerequisites, test commands | `README.md` |
| Build target, project structure, convention | `CLAUDE.md` |

## Steps

1. Identify the changes: the range or commits the user names; else `git diff` for uncommitted work; else the branch against its base (`git diff <remote>/<default-branch>...HEAD`, resolved from the tracked remote — never assume `origin` or `main`)
2. Route each change with the table
3. Edit the owning doc. For ARCHITECTURE.md, verify every path and symbol against the code first; include example request/response JSON for API changes
4. Run `repo-verify-docs`

## Rules

- Document only endpoints and fields the code actually uses
- README links to ARCHITECTURE.md; it does not inline details
- Don't edit generated files
- Never delete a doc file without listing it and getting explicit approval
- No line numbers in docs — paths and symbol names only
- If a Makefile exists, `make` targets are the documented commands; raw tool invocations are implementation notes only
