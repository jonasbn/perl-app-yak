# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

`App::Yak` is a Perl CLI tool (`yak`) that scans directories for files that should match known checksums, helping enforce consistency of copy-pasted files across repositories ("yak shaving"). It compares files against a central checksum registry (`$HOME/.config/yak/checksums.json`) or a per-project `.yaksums.json`.

## Commands

### Install dependencies

```sh
carton install          # installs to local/ using cpanfile.snapshot
# or
cpanm --installdeps .
```

### Run tests

```sh
# Full test suite (includes PerlCritic, POD coverage, kwalitee):
dzil test --all

# Basic tests only:
carton exec perl -Ilib t/test.t

# Single test file:
carton exec prove -lv t/test.t
```

### Lint (Perl::Critic)

```sh
perlcritic --profile t/perlcritic.rc lib/App/Yak.pm script/yak
```

### Run the tool locally

```sh
carton exec perl -Ilib script/yak --about --noconfig --checksums examples/checksums.json
```

### Build distribution

```sh
dzil build
```

## Architecture

The entire library is a single module: `lib/App/Yak.pm`. The CLI entry point is `script/yak`.

**`script/yak`** — parses command line arguments via `Getopt::Long`, creates an `App::Yak` object, calls `read_config`, `read_environment`, `read_checksums` in sequence, then dispatches to `process()` (or informational methods like `print_help`, `print_about`, `print_version`).

**`App::Yak`** — OOP class built on `Class::Accessor`. Key methods:
- `new()` — sets defaults (color on, emoji on, verbose/debug/silent off)
- `read_config($flags)` — reads YAML config from `$HOME/.config/yak/config.yml`; command-line flags passed in override config values
- `read_environment()` — reads `$YAK_*_COLOR` env vars for color overrides
- `read_checksums()` — reads JSON checksums from file or URL; supports `--nochecksums` (forces local `.yaksums.json`), `--checksums <file|url>`, or default `$HOME/.config/yak/checksums.json`
- `process()` — uses `File::Find` to recursively walk `.` and calls `subprocess()` on each file; uses a `Data::Stack` of `Text::Gitignore` matchers to handle nested `.yakignore` files; returns 0 (success) or 1+ (failures)
- `subprocess($file)` — checks a single file against checksums; handles SHA256 checksums, `file://` references, `http(s)://` URLs for dynamic checksum calculation, and boolean presence checks (`true`/`false` in JSON)

**Checksum value types in JSON:**
- `"<sha256hex>"` — exact checksum match
- `"file://FILENAME"` — calculates SHA256 from `$HOME/.config/yak/files/FILENAME`
- `"https://..."` — fetches content and uses SHA256 of that content as checksum
- `true` (JSON boolean) — asserts file presence
- `false` (JSON boolean) — asserts file absence

**`.yakignore` handling:** Hierarchical, gitignore-style. Parent ignores don't cascade into subdirectories that have their own `.yakignore`. Uses a directory stack to track active matchers during `File::Find` traversal.

## Project Files

- `dist.ini` — Dist::Zilla build config; auto-generates `README.md` from POD, runs PerlCritic/POD/kwalitee tests via `dzil test --all`
- `cpanfile` — runtime and test dependencies
- `t/perlcritic.rc` — Perl::Critic config at severity 4; notable: `stop_words_file` points to an absolute path (`/Users/jonasbn/...`), which only works locally
- `.yaksums.json` — this repo checks its own files against itself
- `.yakignore` — tells `yak` to skip `.git` and `local/` when run against this repo

## Code Style

- Perl 5.10+ (`use v5.10`, `say`)
- All constants via `Readonly::Scalar`
- `$TRUE`/`$FALSE`/`$SUCCESS`/`$FAILURE`/`$OK` constants instead of bare `0`/`1`
- POD lives after `__END__`; all public methods must have POD entries (enforced by `PodCoverageTests`)
- Perl::Critic severity 4 enforced; `## no critic (...)` with explicit policy names when suppression is necessary
- `use utf8` in the module; `binmode STDOUT/STDERR ':encoding(UTF-8)'` in the script

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs `dzil test --all` on push. The workflow sets `CONTINUOUS_INTEGRATION=true`, which causes `t/test.t` to run a reduced test set (no interactive assumptions about local config files).
