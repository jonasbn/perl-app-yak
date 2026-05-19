---
name: cpan-dep-auditor
description: Audit cpanfile dependencies — check for unused, redundant, or core-replaceable modules
---

Audit the dependencies declared in `cpanfile` against actual usage in `lib/App/Yak.pm` and `script/yak`.

## Steps

1. **Collect declared dependencies**
   ```bash
   grep -E "^\s*requires" cpanfile
   ```

2. **Collect used modules**
   ```bash
   grep -E "^\s*use " lib/App/Yak.pm script/yak
   ```

3. **Cross-reference**
   - For each module in `cpanfile`, check whether it appears in a `use` statement in either file
   - Flag any declared deps that are never `use`d (candidates for removal)
   - Flag any `use`d modules that are not in `cpanfile` (missing declarations)

4. **Identify core-replaceable modules**
   Check whether any non-core dep could be replaced by a Perl core module:
   - `Readonly` → `use constant` (core)
   - `List::MoreUtils` → `List::Util` (core since 5.7.3)
   - `File::Slurper` → `open`/`do` block (core)
   - Note: only flag as a suggestion, not a finding — core replacements may be intentional trade-offs

5. **Check `on 'test'` deps**
   Repeat the cross-reference for test-only deps against `t/test.t`.

6. **Summarise**
   - Unused deps (safe to remove)
   - Missing deps (should be added)
   - Core-replaceable deps (optional suggestions)
   - Any dep listed under the wrong phase (`requires` vs `on 'test'`)
