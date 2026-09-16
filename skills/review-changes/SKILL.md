---
name: review-changes
description: Use when the user wants code changes reviewed — the current branch's changes against its base, or a GitHub PR (pass the PR number or URL)
allowed-tools: ["Bash(git *)", "Bash(gh *)", "Read", "Skill"]
effort: xhigh
---

# Review Changes

Review a branch or PR against its base. Report findings by severity.

## Step 0: PR eligibility (PR only)

```bash
gh auth status 2>&1
```

Not logged in: **STOP**, tell the user to run `gh auth login`.

```bash
gh pr view $ARGUMENTS --json number,state,author,headRefOid,baseRefName
gh api user --jq .login
gh api "repos/{owner}/{repo}/pulls/<number>/reviews"
```

Skip, and say why, if the PR is closed, automated (e.g. a dependency bump), or your latest review's `commit_id` equals `headRefOid`. Filter reviews to your own login. Don't compare timestamps: your review bumps `updatedAt`, and a force-push can carry an older `committedDate`.

## Step 1: Resolve base, read the change

PR: base is `baseRefName`; diff is `gh pr diff $ARGUMENTS`; intent is `gh pr view $ARGUMENTS --json title,body` plus the commits.

Branch: derive the base from the tracked remote. Never assume `origin` or `main`.

```bash
remote=$(git config "branch.$(git branch --show-current).remote" || git remote | head -1)
base=$(git symbolic-ref --short "refs/remotes/$remote/HEAD" 2>/dev/null \
  || gh repo view --json defaultBranchRef -q "\"$remote/\" + .defaultBranchRef.name" 2>/dev/null)
git log --oneline "$base..HEAD"
git diff "$base...HEAD"
```

If `base` is empty, ask the user.

## Step 2: Review

Read the root CLAUDE.md and any in touched directories; flag clear violations only.

| Category | Check |
| -------- | ----- |
| Correctness | Logic errors, off-by-one, missing null/error checks, resource leaks |
| Security | Secrets, insecure permissions, exposed credentials, injection |
| Shell safety | Unquoted variables, missing `set -euo pipefail`, unsafe globbing |
| Portability | Platform, path, or tool-version assumptions the repo doesn't guarantee |
| Concurrency | Shared mutable state, missing synchronization |
| Tests | Changed behavior without test changes; tests deleted or weakened |
| Style | Naming, dead code, inconsistency with existing patterns |
| Conventions | CLAUDE.md violations |

History: `git blame` the modified code — does the change contradict why it was written that way, or a comment in the file? If blame shows it landed via a reviewed PR (`gh api "repos/{owner}/{repo}/commits/<sha>/pulls"`, `gh pr view <number> --comments`), does that feedback apply again?

Breaking changes: for each changed signature, export, script, build target, config key, env var, CLI flag, or output format, `git grep` its consumers and confirm each still works. Schema changes need a migration.

Docs: if the diff touches paths, symbols, endpoints, config keys, or build targets, invoke `repo-verify-docs` and report its findings. If ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, or CLAUDE.md changed, check them against `repo-lint-docs` rules and report violations. Never edit during a review.

## Step 3: Report

```text
## Critical (must fix before merge)
- deploy.sh — unquoted $TARGET_DIR breaks on paths with spaces

## Important (should fix)
- config/loader.py — new RETRY_LIMIT has no default; a missing env var raises KeyError

## Suggestions
- scripts/fetch.sh — duplicates scripts/download.sh

## Documentation
- scripts/new-tool.sh is not mentioned in ARCHITECTURE.md

## Out of scope
- bin/legacy.sh — pipes curl to bash (predates this change)
```

If the change is good, say so. Don't manufacture issues.

## Rules

- Reference file:line and quote the code
- Verify every finding is real and matters; drop what you can't confirm
- Flag anything this change introduces or triggers, wherever it manifests
- Keep out of main findings: pre-existing issues, formatter-level nits, anything the repo's CI linter/typechecker would catch, lint-silenced issues. Serious pre-existing issues (security, data loss, broken auth) go under "Out of scope", one line each; omit the section if empty
- A possibly intentional behavior change is a question, not a finding
- Use the repo's default `gh` host — no `--hostname` flag
