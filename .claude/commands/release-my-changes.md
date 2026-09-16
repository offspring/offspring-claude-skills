---
description: Bump plugin version (patch/minor/major), commit, and push to the repo's remote
argument-hint: patch|minor|major
allowed-tools: ["Bash(./scripts/check.sh)", "Bash(./scripts/bump-version.sh *)", "Bash(jq *)", "Bash(git *)"]
model: haiku
---

# Release a new version of the plugin

Level: `$ARGUMENTS`. If it is not one of patch, minor, major, ask the user and wait.

Run `./scripts/check.sh` first; stop and report if it fails.

```bash
./scripts/bump-version.sh <level>
version=$(jq -r .version .claude-plugin/plugin.json)
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "Bump to $version"
git push
```

The remote is `offspring`, not `origin`; `push.default = simple` resolves it.
