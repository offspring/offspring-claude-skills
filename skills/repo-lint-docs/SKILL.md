---
name: repo-lint-docs
description: Use when fixing markdown lint issues in documentation files (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md). Edits files in place.
allowed-tools: ["Bash(npx --yes markdownlint-cli2 *)", "Read", "Edit", "Skill"]
model: sonnet
effort: low
---

# Lint Docs

Fix markdown lint issues in place. Files: the ones the user names, else `ARCHITECTURE.md`, `DEVELOPER_GUIDE.md`, `README.md`, `CLAUDE.md` (skip missing).

## Steps

1. Autofix with the repo's `.markdownlint*` config if present:

   ```bash
   npx --yes markdownlint-cli2 --fix <files>
   ```

2. Fix the remainder by hand (autofix can't rename duplicate headings or repair anchors). If the tool is unavailable, apply the table below by hand.
3. If any heading was renamed, run `repo-verify-docs`.

## Rules

| Rule | Fix |
| ---- | --- |
| MD004 | Consistent list marker (`-`) |
| MD009 | No trailing spaces |
| MD010 | Spaces, not tabs |
| MD012 | One blank line max |
| MD023 | Headings start at column 0 |
| MD024 | No duplicate headings in a file |
| MD025 | One H1 per file |
| MD030 | One space after list markers |
| MD031 | Blank line around fenced code blocks |
| MD032 | Blank line around lists |
| MD040 | Language on every fenced block |
| MD047 | Single trailing newline |
| MD051 | Anchor links match an existing heading |

No line numbers in docs — paths and symbol names only.
