---
name: review-changes
description: Use when reviewing code changes — checks for bugs, style, test coverage, breaking changes, and documentation impact
allowed-tools: ["Bash(git *)", "Bash(gh *)", "Read"]
---

# PR Review

Review the current branch's changes against the base branch. Provide actionable feedback organized by severity.

## Process

### Step 0: Verify auth — HARD GATE

If a PR number is provided and `gh` will be used:

```bash
gh auth status 2>&1
```

If not logged in, **STOP**. Tell the user to run `gh auth login` and retry. Do not proceed.

### Step 1: Understand the change

```bash
git log --oneline main..HEAD 2>/dev/null || git log --oneline -5
git diff --stat main..HEAD 2>/dev/null || git diff --stat HEAD~1..HEAD
```

Read the commit messages to understand intent. If a PR number is provided:

```bash
gh pr view $ARGUMENTS --json title,body,files
gh pr diff $ARGUMENTS
```

### Step 2: Review the diff

```bash
git diff main..HEAD 2>/dev/null || git diff HEAD~1..HEAD
```

For each changed file, evaluate:

| Category | What to check |
| -------- | ------------- |
| Correctness | Logic errors, off-by-one, missing null/error checks, resource leaks |
| Security | Secrets in code, insecure permissions, credentials exposed |
| Shell safety | Unquoted variables, missing `set -e`, unsafe globbing |
| Config accuracy | Symlink targets exist, paths are correct |
| Compatibility | macOS-specific assumptions, Homebrew path assumptions |
| Concurrency | Shared mutable state, missing synchronization |
| Style | Naming, dead code, consistency with existing patterns |

### Step 3: Check for breaking changes

- Changed symlink targets in install.conf.yaml
- Changed function signatures, return types, or removed exports
- Removed scripts from bin/ that other scripts depend on
- Changed shell environment variables that other configs reference
- Modified SSH config or GPG config in ways that affect authentication
- Database schema changes without migration

### Step 4: Run companion checks

After reviewing the diff, invoke these skills on the changed files:

- **repo-verify-docs** — if code changes could invalidate documentation references (file paths, function names, endpoints), verify docs accuracy
- **repo-lint-docs** — if any documentation files (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md) were changed, lint them for markdown issues

Skip a check if the changes clearly don't touch its domain.

### Step 5: Check documentation impact

- Do the changes require updates to ARCHITECTURE.md, DEVELOPER_GUIDE.md, or README.md?
- Are new scripts or config files documented?
- Are new symlink mappings documented?

### Step 6: Report

Organize findings by severity:

```text
## Critical (must fix before merge)

- script.sh — unquoted variable expansion could break with spaces in path

## Important (should fix)

- install.conf.yaml — new symlink target ~/.newrc but file newrc doesn't exist in repo

## Suggestions (nice to have)

- bin/utility.sh — duplicates functionality already in bin/existing.sh

## Documentation

- New bin/new-tool.sh needs mention in ARCHITECTURE.md bin/ section
```

If the PR looks good, say so clearly — don't manufacture issues.

## Rules

- Be specific — reference file:line, quote the problematic code
- Distinguish blocking issues from suggestions
- Don't nitpick style that a formatter should handle
- Acknowledge good work — reviews shouldn't be only criticism
- Use the repo's default `gh` host — no `--hostname` flag needed
