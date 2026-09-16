---
name: shell-script
description: Use when writing or editing a bash script, or when the user asks for one
argument-hint: [what the script should do]
paths: ["**/*.sh", "**/*.bash"]
---

# Shell Scripts

If `$ARGUMENTS` is given, write a script that does that. Otherwise apply these rules to the script being edited.

## Conventions

- `#!/usr/bin/env bash`, then `set -euo pipefail`
- Quote every expansion: `"$var"`
- `[[ ]]` not `[ ]`; `$(cmd)` not backticks
- `local` inside functions; `readonly` for constants
- `printf` over `echo`
- `main() { ... }; main "$@"`; a `usage()` when the script takes arguments
- `mktemp` for temp files, `trap ... EXIT` to clean up
- Don't assume `sed`, `awk`, or `find` are GNU on macOS: for GNU-only flags use the `g`-prefixed Homebrew names or guard with a check

## Safety

- No `rm -rf` without a guard on the path
- Check paths before use: `[[ -d "$dir" ]]`, `[[ -f "$file" ]]`

## Verify

```bash
bash -n script.sh
shellcheck script.sh
```

Zero shellcheck warnings before presenting the result.
