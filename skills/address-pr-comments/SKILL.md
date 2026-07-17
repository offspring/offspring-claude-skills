---
name: address-pr-comments
description: Use when the user wants to fetch open PR review comments and address them. Triggered by requests like "check my PR comments", "address review feedback", or "what did reviewers say"
allowed-tools: ["Bash(git *)", "Bash(gh *)", "Read", "Edit", "AskUserQuestion"]
---

# Address PR Comments

Fetch open PRs, show review comments, and address selected ones.

## Process

### Step 1: Verify auth

Verify auth first — **HARD GATE**:

```bash
gh auth status 2>&1
```

If not logged in, **STOP**. Tell the user to run `gh auth login` and retry. Do not proceed.

### Step 2: Find open PRs

```bash
gh pr list
```

If multiple PRs exist, ask the user which one to work on. If only one, proceed with it.

### Step 3: Fetch all PR feedback

Gather feedback in parallel where possible:

**Batch 1 (run in parallel):**
```bash
# Inline review comments (code-level)
gh api repos/{owner}/{repo}/pulls/{number}/comments

# Review-level comments (summary comments left with approve/request changes)
gh api repos/{owner}/{repo}/pulls/{number}/reviews

# General PR comments (conversation-level)
gh pr view {number} --comments
```

**Batch 2 (run in parallel):**
```bash
# CI/CD check results
gh pr checks {number}

# Merge conflict and review status
gh pr view {number} --json mergeable,mergeStateStatus,reviews
```

Separate bot comments (codecov, linters, security scanners) from human comments — present them in a distinct section so the user can focus on human feedback first.

If no feedback exists across any source, report "No review feedback found" and stop.

### Step 4: Present PR status and comments

**First, show a quick status summary:**
- Merge status: mergeable / has conflicts
- Review state: who approved, who requested changes
- CI checks: passing / failing (list failures)
- Bot feedback: codecov deltas, linter warnings, security findings (summarize, don't list every line)

If there are merge conflicts, flag them — the user may want to resolve those before addressing comments.
If CI checks are failing, list the failing checks with links so the user can decide whether to fix those first.

**Check for already-addressed comments.** Compare each comment's `original_commit_id` against the PR's latest commit. If they differ, check whether a subsequent commit already addressed the feedback (read the current file at the commented line). Mark these as **Already addressed** in the table rather than **Skip** — the distinction matters for the reviewer.

**Link bot and human comments.** When a human reviewer references or endorses bot feedback (e.g. "the bot comments may be valid"), present those bot comments alongside the human comment so the user sees the full context and can address them together.

**Then build a numbered table of every human comment.** For each entry show:

| # | Reviewer | File:Line | Comment (summary) | Suggested change? | Proposed action |
|---|----------|-----------|-------------------|--------------------|-----------------|

For each comment include:

- **Diff context** — a few lines from `diff_hunk` so the user has context without opening GitHub
- **Full comment text** — what the reviewer said
- **Suggested change** — if a ` ```suggestion ` block exists, show the current code vs. the proposed change side by side
- **Status** — flag if the thread is already resolved/outdated
- **Proposed action** — your recommendation for how to handle it. One of:
  - **Accept suggestion** — apply the reviewer's suggested change as-is
  - **Accept with modification** — agree with the intent but propose a different implementation (explain why)
  - **Fix differently** — the reviewer identified a real issue but the suggested fix isn't right (show your alternative)
  - **Reply** — no code change needed; post a response on the PR thread explaining rationale (e.g. why a concern doesn't apply, clarifying design intent)
  - **Already addressed** — the comment targets an older commit and a subsequent commit already fixed it. Note which commit addressed it
  - **Discuss** — you're unsure or disagree; flag for the user to decide
  - **Skip** — already resolved, outdated, or purely informational

### Step 5: Ask the user

Present the table and ask the user to confirm or override actions for each comment. Examples:
- "apply all" — accept every proposed action
- "1,3,5 apply; 2 skip; 4 fix differently" — per-comment overrides
- Change any proposed action before proceeding

**Do NOT make any code changes until the user confirms.** Only apply the actions the user approved.

### Step 6: Execute approved actions

For each approved action:

- **Accept suggestion / Accept with modification / Fix differently** — edit the local file, stage changes
- **Reply** — post a threaded reply on the PR comment using `gh api`:
  ```bash
  gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
    -f body="<reply text>"
  ```
  Draft the reply text and show it to the user before posting. Keep replies concise and technical — explain the reasoning, not the process.
- **Already addressed** — optionally reply on the PR thread noting which commit addressed the feedback, so the reviewer knows to re-check

After all code changes are applied, use the `simplify` skill to review the changed code for quality.

### Step 7: Commit

After changes pass review, use the `git-commit` skill to stage and commit with a message referencing the PR feedback.

Summarize what was done: files changed, replies posted, items skipped.

## Notes

- Use `gh` CLI exclusively (not GitHub MCP tools) for fetching PR data
- Use the repo's default `gh` host — no `--hostname` flag needed
- Always show the raw comment before proposing a fix so the user can decide
- **Never auto-apply GitHub suggestion blocks** — present them to the user and wait for explicit approval before making any code changes
- For each suggestion block, show the current code vs. the proposed change so the user can evaluate it
