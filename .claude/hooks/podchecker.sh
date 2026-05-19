#!/bin/bash
# Runs podchecker after edits to .pm, .pod files or script/yak to catch POD errors immediately.

file=$(python3 -c "import json,os; print(json.loads(os.environ.get('CLAUDE_TOOL_INPUT','{}')).get('file_path',''))")

case "$file" in
  *.pm|*.pod|*/script/yak)
    if command -v podchecker >/dev/null 2>&1; then
      podchecker "$file" 2>&1
    fi
    ;;
esac
