#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly PLUGIN_DIR
readonly PLUGIN_JSON="${PLUGIN_DIR}/.claude-plugin/plugin.json"
readonly MARKETPLACE_JSON="${PLUGIN_DIR}/.claude-plugin/marketplace.json"

usage() {
    printf "Usage: %s {major|minor|patch}\n" "$(basename "$0")"
    exit 1
}

bump() {
    local level="$1"
    local old_version
    old_version="$(jq -r .version "${PLUGIN_JSON}")"

    IFS='.' read -r major minor patch <<< "${old_version}"

    case "${level}" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
    esac

    local new_version="${major}.${minor}.${patch}"

    local tmp
    tmp="$(mktemp)"
    jq --arg v "${new_version}" '.version = $v' "${PLUGIN_JSON}" > "${tmp}" && mv "${tmp}" "${PLUGIN_JSON}"

    tmp="$(mktemp)"
    jq --arg v "${new_version}" '.plugins[0].version = $v' "${MARKETPLACE_JSON}" > "${tmp}" && mv "${tmp}" "${MARKETPLACE_JSON}"

    printf "%s -> %s\n" "${old_version}" "${new_version}"
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
    fi

    case "$1" in
        major|minor|patch) bump "$1" ;;
        *) usage ;;
    esac
}

main "$@"
