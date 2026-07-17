---
name: address-pr-comments
description: Use when the user wants to fetch open PR review comments and address them. Triggered by requests like "check my PR comments", "address review feedback", or "what did reviewers say"
allowed-tools: ["Bash(git *)", "Bash(gh *)", "Read", "Edit", "AskUserQuestion", "Skill"]
---

# Address PR Comments

Fetch open PRs, show review comments, and address selected ones.

## Process

### Step 1: Verify auth

**HARD GATE**:

```bash
gh auth status 2>&1
```

If not logged in, **STOP**. Tell the user to run `gh auth login` and retry.

### Step 2: Find open PRs

Run `gh pr list`. If multiple PRs exist, ask the user which one to work on. If only one, proceed with it.

### Step 3: Fetch all PR feedback

Issue these as parallel tool calls (not one sequential script):

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments   # inline review comments
gh api repos/{owner}/{repo}/pulls/{number}/reviews    # review-level comments
gh pr view {number} --comments                        # conversation-level comments
gh pr checks {number}                                 # CI results
gh pr view {number} --json mergeable,mergeStateStatus,reviews
```

If no feedback exists across any source, report "No review feedback found" and stop.

### Step 4: Present PR status and comments

First a status summary: mergeable/conflicts, who approved or requested changes, failing CI checks (with links), and bot feedback (codecov, linters, security scanners) summarized in its own section so the user can focus on human comments first.

**Check for already-addressed comments.** If a comment's `original_commit_id` differs from the PR's latest commit, read the current file at the commented line — a later commit may already address it. Mark these **Already addressed**, not **Skip** — the distinction matters for the reviewer.

**Link bot and human comments.** When a reviewer references or endorses bot feedback, present the two together.

Then build a numbered table of every human comment:

| # | Reviewer | File:Line | Comment (summary) | Suggested change? | Proposed action |
|---|----------|-----------|-------------------|--------------------|-----------------|

For each entry include a few lines of `diff_hunk` context, the full comment text, current code vs. proposed change for any suggestion block, resolved/outdated status, and a proposed action:

- **Accept suggestion** — apply the reviewer's change as-is
- **Accept with modification** — agree with the intent, different implementation (explain why)
- **Fix differently** — real issue, wrong fix (show your alternative)
- **Reply** — no code change; post a response explaining rationale
- **Already addressed** — a later commit fixed it (note which)
- **Discuss** — unsure or disagree; flag for the user to decide
- **Skip** — resolved, outdated, or purely informational

### Step 5: Ask the user

Present the table and ask the user to confirm or override each action (e.g. "apply all", or "1,3,5 apply; 2 skip; 4 fix differently"). **Do NOT make any code changes until the user confirms.** Only apply the actions the user approved.

### Step 6: Execute approved actions

- **Accept suggestion / Accept with modification / Fix differently** — edit the local file, stage changes
- **Reply** — draft the reply, show it to the user, then post a threaded reply:

  ```bash
  gh api repos/{owner}/{repo}/pulls/{pull_number}/comments/{comment_id}/replies \
    -f body="<reply text>"
  ```

- **Already addressed** — optionally reply noting which commit addressed the feedback, so the reviewer knows to re-check

After all code changes are applied, use the `simplify` skill to review the changed code for quality.

### Step 7: Commit

Use the `git-commit` skill to stage and commit with a message referencing the PR feedback. Summarize what was done: files changed, replies posted, items skipped.

## Notes

- Use `gh` CLI exclusively (not GitHub MCP tools), on the repo's default host — no `--hostname` flag needed
- Always show the raw comment before proposing a fix so the user can decide
- Keep replies concise and technical — explain the reasoning, not the process
