# offspring-claude-skills

Personal Claude Code plugin with skills, commands, and workflows.

## Structure

| Directory | Purpose |
| --------- | ------- |
| `.claude-plugin/` | Plugin manifests (plugin.json, marketplace.json) |
| `skills/` | Skills (SKILL.md per directory) |
| `commands/` | Slash commands (.md files) |
| `output-styles/` | Output styles (.md files) |
| `scripts/` | Developer utilities (dev-link.sh, bump-version.sh) |
| `hooks/` | Hook definitions (hooks.json) |
| `agents/` | Agent definitions — empty, add .md files when needed |

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. The `skills` array in `.claude-plugin/plugin.json` points to `./skills/` — new directories are auto-discovered

## Adding a new command

1. Create `commands/<command-name>.md` with YAML frontmatter
2. The `commands` array in `.claude-plugin/plugin.json` points to `./commands/` — new files are auto-discovered

## Adding an output style

1. Create `output-styles/<style-name>.md` with YAML frontmatter (`name`, `description`)
2. The `outputStyles` field in `.claude-plugin/plugin.json` points to `./output-styles/` — new files are auto-discovered

## Adding an agent

1. Create `agents/<agent-name>.md` with YAML frontmatter (`name`, `description`, `model`)
2. Agents are auto-discovered by convention — do NOT add an `agents` field to plugin.json

## GitHub access

- This repo is **public** on github.com (`origin` = `offspring/offspring-claude-skills`) and must stay public so the plugin can be installed from its marketplace. Use the default `gh` host — no `--hostname` flag needed.
- **Restrict writes (pushes, PRs, comments) to the `github.com/offspring` org.** Targeting another org is allowed only when working on or contributing to third-party packages.

## Adding hooks

1. Edit `hooks/hooks.json` with hook definitions
2. Hooks are auto-loaded by convention — do NOT add a `hooks` field to plugin.json
