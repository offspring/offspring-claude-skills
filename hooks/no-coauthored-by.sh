#!/usr/bin/env bash
set -euo pipefail

command="$(jq -r '.tool_input.command // ""')"

if grep -qiE 'co-authored-by|generated with[^"]*claude|noreply@anthropic\.com' <<< "$command"; then
  echo "BLOCKED: AI attribution is forbidden (Co-authored-by, Generated with Claude Code, noreply@anthropic.com). Remove it and retry." >&2
  exit 2
fi
