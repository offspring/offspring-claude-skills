#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

command="$(printf '%s' "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('command', ''))
" 2>/dev/null || echo "")"

if printf '%s' "$command" | grep -qiE 'co-authored-by|generated with[^"]*claude|noreply@anthropic\.com'; then
  echo "BLOCKED: AI attribution is forbidden (Co-authored-by, Generated with Claude Code, noreply@anthropic.com). Remove it and retry." >&2
  exit 2
fi
