#!/usr/bin/env bash
# PreToolUse hook: block git/gh commands that carry AI attribution. Inspects the
# command text only; attribution passed via -F/--body-file is not seen.
set -euo pipefail

readonly PUBLISHING='(^|[;&|[:space:]])(git[[:space:]]+(commit|tag)|gh[[:space:]]+(pr|issue|release))([[:space:]]|$)'
readonly PATTERN='co-authored-by|generated with[^"]*claude|noreply@anthropic\.com'

command="$(jq -r '.tool_input.command // ""')"

if grep -qE "$PUBLISHING" <<< "$command" && grep -qiE "$PATTERN" <<< "$command"; then
  printf 'BLOCKED: AI attribution is forbidden (Co-authored-by, Generated with Claude Code, noreply@anthropic.com). Remove it and retry.\n' >&2
  exit 2
fi
