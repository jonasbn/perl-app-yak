---
name: test-coverage-reporter
description: Run Devel::Cover against the test suite and report uncovered lines, branches, and subroutines in App/Yak.pm; suggests unit tests for internal methods
---

Run `Devel::Cover` against the test suite and summarise which lines, branches, and subroutines in `lib/App/Yak.pm` are not exercised. Also identifies coverage type gaps (integration vs unit tests) and suggests targeted additions.

## Steps

1. **Ensure Devel::Cover is available**
   ```bash
   carton exec perl -MDevel::Cover -e 1 2>&1
   ```
   If missing, add it to `cpanfile` under the existing `on 'test'` block:
   ```
   requires 'Devel::Cover';
   ```
   Then run `carton install` before continuing.

2. **Run coverage** — unset `CONTINUOUS_INTEGRATION` so the full test suite runs (the test file skips most tests when that variable is `true`)
   ```bash
   env -u CONTINUOUS_INTEGRATION carton exec cover -test -select lib/App/Yak.pm 2>&1
   ```

3. **Read the text report**
   ```bash
   carton exec cover -report text -select lib/App/Yak.pm 2>&1
   ```

4. **Identify gaps** — report each uncovered item:
   - **Uncovered subroutines**: methods never called by any test
   - **Uncovered branches**: `if`/`unless`/ternary arms never taken
   - **Uncovered lines**: statements never reached

5. **Note the coverage type gap**
   All current tests in `t/test.t` are CLI-level (`Test::Script`), meaning internal methods (`subprocess`, `read_config`, `read_environment`, `read_checksums`) are only exercised transitively through the script. Flag any method that appears uncovered and is not reachable from the CLI flags used in `t/test.t`.

6. **Suggest unit tests** — for the top 3 uncovered methods, propose a test case in a new `t/unit.t` file that:
   - Creates an `App::Yak` object directly: `my $yak = App::Yak->new`
   - Calls the method in isolation with minimal fixtures
   - Identifies which input or flag combination would exercise the missing branch

7. **Clean up**
   ```bash
   carton exec cover -delete 2>&1
   ```

8. **Summarise**
   - Overall statement / branch / subroutine coverage percentages
   - Top 5 uncovered subroutines by line count
   - Whether gaps are due to missing unit tests vs missing CLI test cases
   - Suggested additions to reach 80%+ branch coverage
