#!/usr/bin/env bash
set -euo pipefail

# Run the behavioral eval suite under evals/ with `claude plugin eval`.
# Calls the model and counts against your usage. Extra arguments are passed
# through, e.g.: ./scripts/eval.sh --case git-commit --runs 1 --ablation none

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly REPO_ROOT

main() {
    cd "$REPO_ROOT"
    if ! compgen -G "evals/*/prompt.md" > /dev/null && ! compgen -G "evals/*/case.yaml" > /dev/null; then
        printf 'No eval cases under evals/. Create the suite with: claude plugin eval init\n' >&2
        exit 1
    fi
    claude plugin eval . --scaffold "$@"
}

main "$@"
