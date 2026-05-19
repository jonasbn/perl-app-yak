---
name: test-coverage-reporter
description: Run Devel::Cover against the test suite and report uncovered lines and branches in App/Yak.pm
---

Run `Devel::Cover` against the test suite and summarise which lines, branches, and subroutines in `lib/App/Yak.pm` are not exercised.

## Steps

1. **Check Devel::Cover is available**
   ```bash
   carton exec perl -MDevel::Cover -e 1 2>&1
   ```
   If not installed, report that `Devel::Cover` needs to be added to `cpanfile` under `on 'test'` and stop.

2. **Run coverage**
   ```bash
   carton exec cover -test -select lib/App/Yak.pm 2>&1
   ```

3. **Read the summary report**
   ```bash
   carton exec cover -report text -select lib/App/Yak.pm 2>&1
   ```

4. **Identify gaps** — for each uncovered item report:
   - **Uncovered subroutines**: methods never called by any test
   - **Uncovered branches**: `if`/`unless`/ternary arms never taken
   - **Uncovered lines**: statements never reached

5. **Suggest test cases** for the top uncovered areas:
   - What input or flag combination would exercise the missing branch?
   - Which existing test in `t/test.t` is closest to covering it?

6. **Clean up**
   ```bash
   carton exec cover -delete 2>&1
   ```

7. **Summarise**
   - Overall statement / branch / subroutine coverage percentages
   - Top 5 uncovered subroutines by line count
   - Suggested test additions to reach 80%+ branch coverage
