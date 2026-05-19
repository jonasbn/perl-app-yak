#!/bin/bash
# Blocks direct edits to README.md — it is Dist::Zilla-generated and should not be edited directly.

file=$(python3 -c "import json,os; print(json.loads(os.environ.get('CLAUDE_TOOL_INPUT','{}')).get('file_path',''))")

if [[ "$file" == *"README.md" ]]; then
    echo "ERROR: README.md is Dist::Zilla-generated. Do not edit it directly, use dzil build." >&2
    exit 2
fi
