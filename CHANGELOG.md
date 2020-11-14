CHANGELOG for `yak`

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
