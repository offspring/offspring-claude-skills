---
name: git-commit
description: Use when staging and committing changes with a well-crafted commit message
allowed-tools: ["Bash(git *)", "Read", "AskUserQuestion"]
---

# Git Commit

Prepare and create a git commit for changes in this repo.

## Process

### Step 1: Review changes

Run in parallel:

```bash
git status -s
git diff --cached --name-only
```

Separate into:

- **Tracked changes** (modified/deleted) — candidates for staging
- **Untracked files** — flag any that should NOT be committed (build artifacts, temp files, secrets)
- **Already staged** — if files are already staged, note them

Three paths for staging:

1. **Nothing staged** — ask the user which files to stage. Never stage without confirmation.
2. **Some files staged, unstaged changes also exist** — commit the staged files only. Skip to Step 2.
3. **All changed files already staged** — skip to Step 2.

Never use `git add -A` or `git add .`. Stage files explicitly by name.

```bash
git add <file1> <file2> ...
```

**Do NOT stage:**

- Build artifacts (.venv/, .mypy_cache/, dist/)
- Secrets or credentials (.env, *.pem, *.key, .secrets/)
- IDE config (.vscode/ unless already tracked)
- Any file matching patterns in .gitignore

### Step 2: Generate commit message

Check existing commit style and the staged diff:

```bash
git log --oneline -5
git diff --cached --stat
```

Rules:

- First line: concise summary under 72 characters
- Explain the WHY, not just the WHAT
- If multiple areas changed, add bullet points in the body
- Use imperative mood ("Update docs" not "Updated docs")
- Match the existing commit message style in the repo

### Step 3: Commit

```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

If the commit fails, check whether GPG signing is enabled:

```bash
git config --get commit.gpgsign
```

If `true`, suggest:
- `gpg --list-keys` to check available keys
- `git config user.signingkey` to verify the configured key
- `GPG_TTY=$(tty) git commit ...` if the pinentry prompt fails

### Step 4: Confirm

```bash
git log --oneline -1
git status -s
```

Report what was committed and whether unstaged changes remain.

### Step 5: Generate PR description (optional)

Only if the user asks for a PR description. Output a copy-pasteable PR description inside a code fence. The title must match the commit's first line exactly.

````markdown
# <commit first line, verbatim>

## Summary

<1-3 bullet points describing what changed and why>

## Changes

<bulleted list of specific changes, grouped by area if needed>

## Test plan

<how to verify the changes work — manual steps, commands to run, or "N/A" for config-only>
````

## Safety

- NEVER use `git add -A` or `git add .`
- NEVER add "Co-authored-by" trailers to commits
- NEVER force push or amend without the user explicitly asking
- If in doubt about a file, ask the user before staging it
