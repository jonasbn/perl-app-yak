#!/bin/bash
# Runs Perl::Critic after edits to .pm files or script/yak.
# Violations are surfaced to Claude as feedback so they can be fixed immediately.

file=$(python3 -c "import json,os; print(json.loads(os.environ.get('CLAUDE_TOOL_INPUT','{}')).get('file_path',''))")

case "$file" in
  *.pm|*/script/yak)
    if command -v perlcritic >/dev/null 2>&1; then
      perlcritic --profile t/perlcritic.rc "$file"
    fi
    ;;
esac
