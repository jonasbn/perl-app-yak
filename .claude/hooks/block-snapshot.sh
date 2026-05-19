#!/bin/bash
# Blocks direct edits to cpanfile.snapshot — it is Carton-generated.

file=$(python3 -c "import json,os; print(json.loads(os.environ.get('CLAUDE_TOOL_INPUT','{}')).get('file_path',''))")

if [[ "$file" == *"cpanfile.snapshot" ]]; then
    echo "ERROR: cpanfile.snapshot is Carton-generated. Run 'carton install' to update it." >&2
    exit 2
fi
