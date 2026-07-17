---
name: review-changes
description: Use when the user wants code changes reviewed — the current branch's changes against its base, or a GitHub PR (pass the PR number or URL)
allowed-tools: ["Bash(git *)", "Bash(gh *)", "Read", "Skill"]
---

# PR Review

Review the current branch's changes against the base branch. Provide actionable feedback organized by severity.

## Process

### Step 0: Verify auth and eligibility

If a PR number is provided and `gh` will be used, verify auth first — **HARD GATE**:

```bash
gh auth status 2>&1
```

If not logged in, **STOP**. Tell the user to run `gh auth login` and retry. Do not proceed.

Then check the PR is worth reviewing:

```bash
gh pr view $ARGUMENTS --json state,author,headRefOid
gh api user --jq .login
gh api "repos/{owner}/{repo}/pulls/$ARGUMENTS/reviews"
```

Skip the review if the PR is closed, automated (e.g. a dependency bump), or already reviewed by you with nothing new since. The reviews endpoint returns everyone's reviews, so first filter to yours — the ones whose `user.login` matches the login from `gh api user --jq .login`. "Nothing new" means your latest review's `commit_id` matches the PR's `headRefOid` — no code has changed since you reviewed. Don't compare timestamps: your own review bumps the PR's `updatedAt`, and a force-push can carry an older `committedDate`. If skipping, say why and stop.

### Step 1: Understand the change

```bash
# for a PR, prefer: gh pr view $ARGUMENTS --json baseRefName -q .baseRefName
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
git log --oneline "$base..HEAD" 2>/dev/null || git log --oneline -5
git diff --stat "$base...HEAD" 2>/dev/null || git diff --stat HEAD~1..HEAD
```

If the base can't be resolved, the `HEAD~1..HEAD` fallback covers only the last commit — say so in the report.

Read the commit messages to understand intent. If a PR number is provided:

```bash
gh pr view $ARGUMENTS --json title,body,files
gh pr diff $ARGUMENTS
```

### Step 2: Review the diff

```bash
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
git diff "$base...HEAD" 2>/dev/null || git diff HEAD~1..HEAD
```

Read the root CLAUDE.md and any CLAUDE.md files in directories the change touches. CLAUDE.md is guidance for writing code — not every instruction applies at review time, but flag clear violations.

For each changed file, evaluate:

| Category | What to check |
| -------- | ------------- |
| Correctness | Logic errors, off-by-one, missing null/error checks, resource leaks |
| Security | Secrets in code, insecure permissions, credentials exposed |
| Shell safety | Unquoted variables, missing `set -e`, unsafe globbing |
| Config accuracy | Symlink targets exist, paths are correct |
| Compatibility | macOS-specific assumptions, Homebrew path assumptions |
| Concurrency | Shared mutable state, missing synchronization |
| Test coverage | New or changed behavior with no test updates; tests deleted or weakened |
| Style | Naming, dead code, consistency with existing patterns |
| Conventions | Violations of root or per-directory CLAUDE.md guidance |

Then check the change against its history:

- `git log --follow` and `git blame` on the modified code — does the change conflict with the reason the code was written that way?
- Code comments in the modified files — does the change violate guidance in those comments?
- If the repo is on GitHub: comments on previous PRs that touched these files — does earlier review feedback apply again? (`git log --format='%H' -- <path>` for the commits, `gh api "repos/{owner}/{repo}/commits/<sha>/pulls"` for their PRs, then `gh pr view <number> --comments`)

### Step 3: Check for breaking changes

Trace the impact: for each symbol whose behavior, signature, or output changed, `git grep` its callers and consumers and verify each still gets what it expects. Prioritize shared/exported symbols; file-local helpers only need their in-file callers checked. A small change can break code far from the lines in the diff.

Common cases:

- Changed symlink targets in install.conf.yaml
- Changed function signatures, return types, or removed exports
- Removed scripts from bin/ that other scripts depend on
- Changed shell environment variables that other configs reference
- Modified SSH config or GPG config in ways that affect authentication
- Database schema changes without migration

### Step 4: Run companion checks

After reviewing the diff:

- **repo-verify-docs** — if code changes could invalidate documentation references (file paths, function names, endpoints), invoke it to verify docs accuracy
- If any documentation files (ARCHITECTURE.md, DEVELOPER_GUIDE.md, README.md, CLAUDE.md) were changed, check them against the rules in `repo-lint-docs` and report violations as findings — do not edit files during a review

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

## Out of scope

- bin/legacy.sh — pipes curl to bash for an unpinned remote script (predates this change)
```

If the PR looks good, say so clearly — don't manufacture issues.

## Rules

- Be specific — reference file:line, quote the problematic code
- Distinguish blocking issues from suggestions
- Verify each issue before reporting it — confirm it is real and likely to matter in practice; drop anything you can't confirm
- The test is causation, not line numbers: flag anything this change introduces or triggers, wherever it manifests
- Find everything while reviewing; filter only when writing the report
- Keep out of the main findings — but put serious ones (security, data loss, broken auth) in the "Out of scope" section rather than dropping them, one line each, omitting the section if there are none:
  - Issues that predate the change
  - Style nitpicks a formatter would fix
  - Issues a linter, typechecker, or compiler would catch, if the repo has CI that runs them
  - Pedantic nitpicks a senior engineer wouldn't call out
  - Issues explicitly silenced in the code (e.g. a lint-ignore comment)
- If a functionality change might be intentional, report it as a question, not a finding
- Acknowledge good work — reviews shouldn't be only criticism
- Use the repo's default `gh` host — no `--hostname` flag needed
