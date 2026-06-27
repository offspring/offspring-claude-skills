#!/usr/bin/env bash
set -euo pipefail

# Link/unlink this plugin into the Claude Code plugin cache for local testing.
# Usage:
#   ./dev-link.sh link     — symlink into cache and register
#   ./dev-link.sh unlink   — remove symlink and deregister

readonly PLUGIN_NAME="offspring-claude-skills"
readonly MARKETPLACE="offspring-claude-plugins"
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly PLUGIN_DIR
VERSION="$(jq -r .version "${PLUGIN_DIR}/package.json")"
readonly VERSION
readonly CACHE_BASE="${HOME}/.claude/plugins/cache/${MARKETPLACE}/${PLUGIN_NAME}"
readonly CACHE_TARGET="${CACHE_BASE}/${VERSION}"
readonly INSTALLED_PLUGINS="${HOME}/.claude/plugins/installed_plugins.json"
readonly PLUGIN_KEY="${PLUGIN_NAME}@${MARKETPLACE}"

usage() {
    printf "Usage: %s {link|unlink}\n" "$(basename "$0")"
    exit 1
}

link() {
    if [[ -e "${CACHE_TARGET}" ]]; then
        printf "Already linked: %s\n" "${CACHE_TARGET}"
        exit 1
    fi

    mkdir -p "${CACHE_BASE}"
    ln -s "${PLUGIN_DIR}" "${CACHE_TARGET}"
    printf "Linked: %s -> %s\n" "${CACHE_TARGET}" "${PLUGIN_DIR}"

    if [[ -f "${INSTALLED_PLUGINS}" ]]; then
        local now
        now="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
        local tmp
        tmp="$(mktemp)"
        jq --arg key "${PLUGIN_KEY}" \
           --arg path "${CACHE_TARGET}" \
           --arg ver "${VERSION}" \
           --arg now "${now}" \
           '.plugins[$key] = [{
               scope: "user",
               installPath: $path,
               version: $ver,
               installedAt: $now,
               lastUpdated: $now
           }]' "${INSTALLED_PLUGINS}" > "${tmp}" \
        && mv "${tmp}" "${INSTALLED_PLUGINS}"
        printf "Registered in installed_plugins.json\n"
    fi

    printf "Restart Claude Code to pick up the plugin.\n"
}

unlink() {
    if [[ -L "${CACHE_TARGET}" ]]; then
        rm "${CACHE_TARGET}"
        printf "Removed symlink: %s\n" "${CACHE_TARGET}"
        rmdir "${CACHE_BASE}" 2>/dev/null || true
    elif [[ -e "${CACHE_TARGET}" ]]; then
        printf "Error: %s exists but is not a symlink. Not removing.\n" "${CACHE_TARGET}"
        exit 1
    else
        printf "Not linked: %s\n" "${CACHE_TARGET}"
    fi

    if [[ -f "${INSTALLED_PLUGINS}" ]]; then
        local tmp
        tmp="$(mktemp)"
        jq --arg key "${PLUGIN_KEY}" \
           'del(.plugins[$key])' "${INSTALLED_PLUGINS}" > "${tmp}" \
        && mv "${tmp}" "${INSTALLED_PLUGINS}"
        printf "Deregistered from installed_plugins.json\n"
    fi

    printf "Restart Claude Code to apply.\n"
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
    fi

    case "$1" in
        link)   link ;;
        unlink) unlink ;;
        *)      usage ;;
    esac
}

main "$@"
