---
name: repo-lint-docs
description: Use when fixing markdown lint issues in documentation files (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md). Edits files in place.
allowed-tools: ["Read", "Edit"]
---

# Lint Docs

Check and fix markdown lint issues across documentation files. Edit files directly — do not just report.

## When to Activate

- Before committing documentation changes
- After generating or heavily editing a doc
- When the IDE shows markdown lint warnings in a doc file

## Files to Lint

- `ARCHITECTURE.md`
- `DEVELOPER_GUIDE.md`
- `README.md`
- `CLAUDE.md`

## Rules to Enforce

| Rule | What to fix |
| ---- | ----------- |
| MD009 | Remove trailing spaces from all lines |
| MD010 | Replace hard tabs with spaces |
| MD012 | Collapse multiple consecutive blank lines into one |
| MD023 | Ensure headings start at the beginning of the line (no leading spaces) |
| MD024 | Remove or rename duplicate headings within the same file |
| MD025 | Ensure only one H1 (`#`) per file |
| MD030 | Use consistent list marker style (`-` preferred) |
| MD031 | Add a blank line before and after every fenced code block |
| MD032 | Add a blank line before and after every list |
| MD040 | Add a language identifier to every fenced code block |
| MD047 | Ensure every file ends with a single trailing newline |
| MD051 | Fix any anchor links (`[text](#anchor)`) that don't match an existing heading |

## Rules

- Do NOT use line numbers in documentation — reference file paths and symbol names only

## Steps

1. Read each file
2. Apply all fixes above
3. Write the corrected file back
4. Run `repo-verify-docs` if any structural edits were made (e.g. headings renamed)
