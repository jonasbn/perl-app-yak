#!/bin/bash
# Runs perl -c after edits to .pm files or script/yak to catch syntax errors immediately.

file=$(python3 -c "import json,os; print(json.loads(os.environ.get('CLAUDE_TOOL_INPUT','{}')).get('file_path',''))")

case "$file" in
  *.pm|*/script/yak)
    perl -c -Ilib "$file" 2>&1
    exit $?
    ;;
esac
