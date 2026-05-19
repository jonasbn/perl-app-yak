---
name: changelog-consistency-checker
description: Verify that CHANGELOG top entry matches the module VERSION and that API changes since the last tag are documented
---

Verify that `CHANGELOG` is consistent with the current module version and that public API changes are reflected in it.

## Steps

1. **Read the current module version**
   ```bash
   grep -m1 "^\$VERSION\|^our \$VERSION\|^VERSION" lib/App/Yak.pm
   ```

2. **Read the top CHANGELOG entry**
   ```bash
   grep -m1 "^## " CHANGELOG
   ```
   - Confirm the version number in the top `## X.Y.Z` line matches `$VERSION` in the module
   - Flag a mismatch as a blocker for release

3. **Find the last release tag**
   ```bash
   git tag --sort=-version:refname | head -5
   ```

4. **Diff public API since last tag**
   ```bash
   git diff $(git tag --sort=-version:refname | head -1)..HEAD -- lib/App/Yak.pm script/yak
   ```
   Look for:
   - New `sub` definitions (added public methods)
   - Removed `sub` definitions (removed public methods)
   - New or changed `=head2` POD entries
   - New command-line options added to `script/yak`
   - Changes to `mk_accessors` list

5. **Cross-reference against CHANGELOG**
   For each API change found in step 4, check whether the top CHANGELOG entry mentions it.
   - Flag any undocumented additions or removals

6. **Check date format**
   Confirm the top entry date is in `YYYY-MM-DD` format and is plausible (not in the future, not more than 6 months old for an unreleased version).

7. **Summarise**
   - Version match: OK or mismatch (with values)
   - Undocumented API changes (list each)
   - Documented changes that look complete
   - Overall verdict: ready to release / needs CHANGELOG update
