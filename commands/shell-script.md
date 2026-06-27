---
argument-hint: <description of what the script should do>
---

Write a shell script that: $ARGUMENTS

## Requirements

- Use `#!/usr/bin/env bash` shebang
- Start with `set -euo pipefail`
- Quote all variable expansions: `"$var"` not `$var`
- Use `[[ ]]` for conditionals, not `[ ]`
- Prefer `$(command)` over backticks
- Use `local` for variables inside functions
- Use `readonly` for constants
- Use `printf` over `echo` for portable output
- Handle missing arguments with a `usage` function
- On macOS, use `gsed`/`gawk` when GNU behavior is needed
- MUST pass `shellcheck` with zero warnings

## Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Brief description

usage() {
    printf "Usage: %s <args>\n" "$(basename "$0")"
    exit 1
}

main() {
    local tmp
    tmp="$(mktemp)"
    trap 'rm -f "${tmp}"' EXIT

    # ...
}

main "$@"
```

## Safety

- Never use `rm -rf` without confirmation or guard conditions
- Validate paths before operating on them
- Use `mktemp` for temporary files
- Trap EXIT to clean up temporary resources

## Verification

After writing the script, run both checks:

```bash
bash -n script.sh
shellcheck script.sh
```

Fix any issues before presenting the result.
