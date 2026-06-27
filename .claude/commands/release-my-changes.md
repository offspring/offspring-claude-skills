---
name: release-my-changes
description: Bump plugin version (patch/minor/major), commit, and push to origin
allowed-tools: ["Bash(./scripts/bump-version.sh *)", "Bash(jq *)", "Bash(git *)"]
---

# Release a new version of the plugin

## Steps

1. Ask the user which version bump: patch, minor, or major. Wait for their answer before proceeding.

2. Run the bump script with the chosen level:

```bash
./scripts/bump-version.sh <level>
```

1. Read the new version from plugin.json:

```bash
jq -r .version .claude-plugin/plugin.json
```

1. Stage the two changed files and commit:

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "Bump to <new_version>"
```

1. Push to origin:

```bash
git push origin HEAD
```
