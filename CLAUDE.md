# offspring-claude-skills

Personal Claude Code plugin with skills, hooks, and an output style.

## Structure

| Directory | Purpose |
| --------- | ------- |
| `.claude-plugin/` | Plugin manifests (plugin.json, marketplace.json) |
| `skills/` | Skills (SKILL.md per directory) |
| `output-styles/` | Output styles (.md files) |
| `hooks/` | hooks.json plus hook scripts |
| `agents/` | Agent definitions (.md), currently empty |
| `scripts/` | check.sh (static checks, run by `/test` and `/release-my-changes`), eval.sh (`claude plugin eval` wrapper), dev-link.sh, bump-version.sh |

`skills/`, `output-styles/`, `hooks/`, and `agents/` are discovered by convention. plugin.json holds metadata only — do not add `skills`, `commands`, `outputStyles`, `hooks`, or `agents` fields.

## Adding things

- Skill: `skills/<name>/SKILL.md` with `name` and `description` frontmatter. Trigger conditions in the description, not the workflow.
- Output style: `output-styles/<name>.md` with `name` and `description`.
- Agent: `agents/<name>.md` with `name`, `description`, `model`.
- Hook: edit `hooks/hooks.json`.

Don't duplicate global rules from `~/.claude/CLAUDE.md` and `~/.claude/rules/` (the dotfiles repo) in skills; skills hold only what the workflow itself needs.

## GitHub access

- Public repo on github.com; remote `offspring` = `offspring/offspring-claude-skills`, no `origin`. Must stay public so the plugin installs from its marketplace.
- Restrict writes (pushes, PRs, comments) to the `github.com/offspring` org unless contributing to a third-party package.
