---
name: yak-self-check
description: Run yak against this repository and explain any checksum failures or missing files tracked in .yaksums.json
---

Run App::Yak against this repository and interpret the results.

## Steps

1. Run yak in verbose mode:
   ```bash
   carton exec perl -Ilib script/yak --verbose 2>&1
   ```

2. Parse the output:
   - `succeeded` / `✅` — file present and checksum matches; count for summary
   - `failed` / `❗️` — file missing or checksum mismatch; needs action
   - `ignored` — skipped per `.yakignore`; expected

3. For each **failure**, determine the cause:
   - **File missing**: entry exists in `.yaksums.json` but the file is not in this repo
   - **Checksum mismatch**: file exists but content has changed since the entry was recorded
     - Run `shasum -a 256 <filename>` to get the current SHA256
     - Show the old value from `.yaksums.json` alongside the new value

4. **Summarize**:
   - Total files checked / passed / failed
   - Exact `.yaksums.json` edits needed (old value → new value, or entries to add/remove)
   - Whether the mismatch is expected (intentional local change) or should be fixed
