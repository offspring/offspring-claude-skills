#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

command="$(printf '%s' "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('command', ''))
" 2>/dev/null || echo "")"

if printf '%s' "$command" | grep -qi 'co-authored-by'; then
  echo "BLOCKED: Co-authored-by trailers are forbidden. Remove the Co-authored-by line and retry." >&2
  exit 2
fi
