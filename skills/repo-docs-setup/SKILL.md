---
name: repo-docs-setup
description: Use when a repo needs standardized documentation (CLAUDE.md, ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md) set up or refreshed. Safe to re-run on already-set-up repos.
allowed-tools: ["Bash(git *)", "Bash(grep *)", "Bash(find *)", "Bash(ls *)", "Read", "Edit", "Write", "AskUserQuestion", "Skill"]
---

# Repo Documentation Setup

Set up standardized documentation for the current repo.

Read and follow the full template in `template.md` (in this skill's directory). It contains all steps and section templates.

## Quick Reference

| Step | What |
|------|------|
| 1 | Explore the codebase |
| 2 | Consolidate existing docs into 4 target files |
| 3 | Create / update CLAUDE.md |
| 4 | Create / update ARCHITECTURE.md |
| 5 | Create / update DEVELOPER_GUIDE.md / README.md |
| 6 | Clean up old docs (ask user before deleting), then run `repo-verify-docs` and `repo-lint-docs` |
| 7 | Verify everything |
| 8 | Offer to commit (ask first) via `git-commit`, after a `simplify` pass on any new scripts |

## GitHub Access

- Use the repo's default `gh` host — no `--hostname` flag needed
