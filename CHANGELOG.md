CHANGELOG for `yak`

# 0.3.0 Milestone release, implementing about command line option

- Added command line arguments `--about` and it emits:
- current version number of `yak`
- configuration file location/path
- data source (file) location/path
- invocation command line arguments, including `--about`
- invocation environment (meaning the sum of configuration and invocation), currently just the configuration file contents, not the sum

# 0.2.0 Milestone release, implementing initial Docker support

- `yak` can now be build as a Docker container
- Added command line arguments are:
  - `--noconfig` disables reading of `$HOME/.config/yak/config.yml` so invocation relies solely on command line arguments
  - `--nochecksums` disables reading of `$HOME/.config/yak/checksums.yml` so checksum data has to be read from the directory in which `yak` is executed and it has to be names `.yaksums.json`,
- The command line arguments: `--noconfig` and `--nochecksums` are mandatory for the Docker entrypoint

# 0.1.0 Milestone release, implementing initial features

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
