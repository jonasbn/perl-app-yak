# CHANGELOG for `yak`

## 0.13.0 2020-12-04 Milestone release, implementing support for checking file presence

- Added support for checking file presence
  - in the data source (checksums file) you can now specify a _boolean_ instead of a checksum or file
  - `true` meaning that `yak` succeeds if the file is present and fails if not
  - `false` meaning that `yak` succeeds if the file is not present and fails if it is

## 0.12.0 2020-12-04 Milestone release, implementing support for `.yakignore` and configuration of file ignores

- Added support for ignoring files
  - adding local `.yakignores` for deep directory trees
  - added patterns to configuration under `ignore_dirs:`
  - the `.yakignores` and `ignore_dirs` is based on an `.gitignore` implementation

## 0.11.0 2020-11-26 Milestone release, implementing environment output in `--about`

- `--about` now outputs the values of relevant environment variables
  - outputs value of `$CLICOLOR` if defined
  - outputs value of `$CLICOLOR_FORCE` if defined

## 0.10.0 2020-11-25 Milestone release, implementing support for controlling colorized output using environment

- Added support for environment variable `$CLICOLOR`
  - overrides config can be overridden by command line flags
- Added support for environment variable `$CLICOLOR_FORCE`
  - overrides config, `$CLICOLOR` and command line flags

## 0.9.0 2020-11-22 Milestone release, implementing support for custom emojis

- Added configuration option `success_emoji`
  - can be configured in: `$HOME/.config/yak/config.yaml`
  - can be used to override default emoji for successful checks

- Added configuration option `failure_emoji`
  - can be configured in: `$HOME/.config/yak/config.yaml`
  - can be used to override default emoji for failing checks

- Added configuration option `skip_emoji`
  - can be configured in: `$HOME/.config/yak/config.yaml`
  - can be used to override default emoji for skipped checks

## 0.8.0 2020-11-21 Milestone release, implementing emoji output control

- Added configuration option `emoji`
  - can be configured in: `$HOME/.config/yak/config.yaml`
  - can be used to override default value of enabled

- Added command line argument `--emoji`
  - can be used to override `emoji` configuration specified in: `$HOME/.config/yak/config.yaml`

- Added command line argument `--noemoji`
  - overriding default value of enabled
  - can be used to override `emoji` configuration specified in: `$HOME/.config/yak/config.yaml`
  - overriding `--emoji` command line argument

## 0.7.0 2020-11-21 Milestone release, implementing color output control

- Added configuration option `color`
  - can be configured in: `$HOME/.config/yak/config.yaml`
  - can be used to override default value of enabled

- Added command line argument `--color`
  - can be used to override `color` configuration specified in: `$HOME/.config/yak/config.yaml`

- Added command line argument `--nocolor`
  - overriding default value of enabled
  - can be used to override `color` configuration specified in: `$HOME/.config/yak/config.yaml`
  - overriding `--color` command line argument

## 0.6.0 2020-11-21 Milestone release, implementing checksums command line option

- Added command line argument `--config <data source file>`
  - using specified data source file instead of the default: `$HOME/.config/yak/checksums.json`
  - fixed a minor bug introduced in mile stone release 0.5.0 where `--about` would emit nonsense

## 0.5.0 2020-11-19 Milestone release, implementing config command line option

- Added command line argument `--config <configuration file>`
  - using specified configuration file instead of the default: `$HOME/.config/yak/config.yaml`

## 0.4.0 2020-11-19  Milestone release, implementing help command line option

- Added command line argument `--help` and it emits:
  - listing of all command line options with short description

## 0.3.0 2020-11-17 Milestone release, implementing about command line option

- Added command line argument `--about` and it emits:
- current version number of `yak`
- configuration file location/path
- data source (file) location/path
- invocation command line arguments, including `--about`
- invocation environment (meaning the sum of configuration and invocation), currently just the configuration file contents, not the sum

## 0.2.0 2020-11-16 Milestone release, implementing initial Docker support

- `yak` can now be build as a Docker container
- Added command line arguments are:
  - `--noconfig` disables reading of `$HOME/.config/yak/config.yml` so invocation relies solely on command line arguments
  - `--nochecksums` disables reading of `$HOME/.config/yak/checksums.yml` so checksum data has to be read from the directory in which `yak` is executed and it has to be names `.yaksums.json`,
- The command line arguments: `--noconfig` and `--nochecksums` are mandatory for the Docker entrypoint

## 0.1.0 2020-11-14 Milestone release, implementing initial features

- Can be configured using file and configuration supports:
  - `verbosity` tells `yak` to emit more verbose output
  - `debug` tells `yak` to emit debug output
  - the configuration file is in YAML and has to be placed in: `$HOME/.config/yak/config.yml`
- Can take command line arguments, currently supported is
  - `--verbose` overwrites config and tells `yak` to emit more verbose output
  - `--debug` overwrites config and tells `yak` to emit debug output
  - `--silent` silences `yak` and you have to rely on the return value
  - `--nodebug` tells `yak` not to output debug no matter configuration or commandline flag `--debug` (see above)
- Persistent data for `yak` is supported
  - data has to be written to a JSON file placed in: `$HOME/.config/yak/checksums.json`
