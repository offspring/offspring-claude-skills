#!/usr/bin/env bash
set -euo pipefail

# Static checks to run before a release. Behavioral evals live in scripts/eval.sh.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly REPO_ROOT
readonly HOOK="hooks/no-coauthored-by.sh"

fail=0

step() { printf '\n== %s\n' "$1"; }
err() {
    printf 'FAIL: %s\n' "$1" >&2
    fail=1
}

check_manifests() {
    step "Plugin manifests"
    claude plugin validate . || err "marketplace manifest invalid"
    claude plugin validate .claude-plugin/plugin.json || err "plugin manifest invalid"

    local f
    for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
        jq empty "$f" || err "$f is not valid JSON"
    done

    local v_plugin v_market
    v_plugin="$(jq -r .version .claude-plugin/plugin.json)"
    v_market="$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)"
    [[ "$v_plugin" == "$v_market" ]] || err "version mismatch: plugin.json ${v_plugin}, marketplace.json ${v_market}"
}

check_shell() {
    step "Shell scripts"
    local f
    for f in scripts/*.sh hooks/*.sh; do
        bash -n "$f" || err "$f: syntax error"
        shellcheck "$f" || err "$f: shellcheck warnings"
    done
}

check_frontmatter() {
    step "Skill and command frontmatter"
    local f dir name desc
    for f in skills/*/SKILL.md; do
        dir="$(basename "$(dirname "$f")")"
        name="$(yq --front-matter=extract '.name // ""' "$f")"
        desc="$(yq --front-matter=extract '.description // ""' "$f")"
        [[ "$name" == "$dir" ]] || err "$f: name '${name}' does not match directory '${dir}'"
        [[ -n "$desc" ]] || err "$f: missing description"
        (( ${#desc} <= 1024 )) || err "$f: description longer than 1024 characters"
    done
    for f in .claude/commands/*.md; do
        desc="$(yq --front-matter=extract '.description // ""' "$f")"
        [[ -n "$desc" ]] || err "$f: missing description"
    done
}

check_markdown() {
    step "Markdown lint"
    npx --yes markdownlint-cli2 "skills/**/*.md" "*.md" ".claude/commands/*.md" || err "markdown lint issues"
}

check_hook() {
    step "Attribution hook"
    local blocked allowed rc
    blocked='{"tool_input":{"command":"git commit -m x -m \"Co-Authored-By: someone <s@example.com>\""}}'
    allowed='{"tool_input":{"command":"git commit -m \"Fix typo\""}}'

    set +e
    bash "$HOOK" <<< "$blocked" 2>/dev/null
    rc=$?
    set -e
    (( rc == 2 )) || err "${HOOK}: attribution not blocked (exit ${rc}, expected 2)"

    set +e
    bash "$HOOK" <<< "$allowed"
    rc=$?
    set -e
    (( rc == 0 )) || err "${HOOK}: clean command blocked (exit ${rc})"
}

main() {
    cd "$REPO_ROOT"
    check_manifests
    check_shell
    check_frontmatter
    check_markdown
    check_hook

    if (( fail )); then
        printf '\nChecks failed\n' >&2
        exit 1
    fi
    printf '\nAll checks passed\n'
}

main "$@"
