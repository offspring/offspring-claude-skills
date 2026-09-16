---
name: address-pr-comments
description: Use when the user wants to fetch open PR review comments and address them. Triggered by requests like "check my PR comments", "address review feedback", or "what did reviewers say"
allowed-tools: ["Bash(git *)", "Bash(gh *)", "Read", "Edit", "AskUserQuestion", "Skill"]
---

# Address PR Comments

## Step 1: Auth and account

```bash
gh auth status 2>&1
git remote -v
```

Not logged in: **STOP**, tell the user to run `gh auth login`. If several accounts are logged in, the active one must match the owner in the remote URL; otherwise `gh auth switch --user <account>` before continuing.

## Step 2: Find the PR

`gh pr view --json number,title,url` resolves the current branch's PR. If none, `gh pr list --author @me`; ask which one unless exactly one.

## Step 3: Fetch feedback

Parallel calls (`gh` fills `{owner}/{repo}`):

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments   # inline review comments
gh api repos/{owner}/{repo}/pulls/<number>/reviews    # review-level comments
gh pr view <number> --comments                        # conversation comments
gh pr checks <number>                                 # CI
gh pr view <number> --json mergeable,mergeStateStatus,reviews
```

No feedback anywhere: report "No review feedback found" and stop.

## Step 4: Present

Status first: mergeable/conflicts, approvals and change requests, failing checks with links. Bot feedback (codecov, linters, scanners) in its own section; when a reviewer endorses bot feedback, present the two together.

If a comment's `original_commit_id` isn't the PR head, read the current code at that line — a later commit may already address it. Mark those **Already addressed**, not **Skip**.

Then a numbered table of human comments:

| # | Reviewer | File:Line | Comment | Suggested change? | Proposed action |
|---|----------|-----------|---------|-------------------|-----------------|

Per entry: a few lines of `diff_hunk`, the full comment, current vs proposed code for suggestion blocks, resolved/outdated status, and one action:

- **Accept suggestion** — apply as-is
- **Accept with modification** — same intent, different implementation (say why)
- **Fix differently** — real issue, wrong fix (show yours)
- **Reply** — no code change; explain rationale
- **Already addressed** — note the commit
- **Discuss** — unsure or disagree; user decides
- **Skip** — resolved, outdated, or informational

## Step 5: Confirm

Ask the user to confirm or override each action (e.g. "apply all", "1,3,5 apply; 2 skip; 4 fix differently"). **No code changes before confirmation.**

## Step 6: Execute

- Code actions: edit and stage
- **Reply**: draft, show the user, then post

  ```bash
  gh api repos/{owner}/{repo}/pulls/<number>/comments/<comment_id>/replies -f body="<reply>"
  ```

- **Already addressed**: optionally reply naming the commit

Then run `simplify` on the changed code and `git-commit` with a message referencing the feedback. Summarize: files changed, replies posted, items skipped.

## Notes

- `gh` CLI only (not GitHub MCP tools), default host, no `--hostname`
- Show the raw comment before proposing a fix
- Replies: concise and technical — reasoning, not process
