---
name: git-commit
description: Use when staging and committing changes with a well-crafted commit message
allowed-tools: ["Bash(git *)", "Read", "AskUserQuestion"]
effort: medium
---

# Git Commit

## Step 1: Stage

```bash
git status -s
```

- Nothing staged: ask which files to stage. Never stage without confirmation.
- Some staged, more unstaged: commit only the staged files.
- Everything staged: continue.

Stage by name, never `git add -A` or `git add .`. Don't stage build artifacts, secrets (`.env`, `*.pem`, `*.key`, `.secrets/`), IDE config, or anything `.gitignore` matches. If in doubt, ask.

## Step 2: Message

```bash
git log --oneline -5
git diff --cached
```

Match the repo's existing message style. Bullets in the body only when several areas changed.

## Step 3: Commit and confirm

```bash
git commit -m "$(cat <<'EOF'
<message>
EOF
)"
git log --oneline -1
git status -s
```

Report what was committed and whether unstaged changes remain. Never force-push or amend unless the user asks.
