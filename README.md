:warning: WARNING! :warning:

This this project and it's components are WIP and *alpha* software, everything is far from working and even farther from finished

---

# yak

yak - script to help with yak shaving for example GitHub projects

# DESCRIPTION

The `yak` _shaver_ can scan a directory for files, which can be classified as yaks in need of shaving. Meaning files which are maintained else where are often copy-pasted.

The file names can be configured in a central configuration file, like this:

`$HOME/.config/yak/checksums.json`

    {
        "CONTRIBUTING.md": "15701b6b27e1d49ca6636f2695cfc49b6622c7152f74b14becc53850811db54f"
    }

If a file is encountered, which matches the name, the checksum of the encountered file is calculated and is compared to the checksum listed in the central file.

- If they match, everything is okay
- If they differ, the difference has to be addressed

The recommendation is to have the checksum in the central file, reflect the authoritative revision and hence you can overwrite the file in the directory you where inspecting.

Alternatively to specifying a checksum, you can specify a file URL:

    {
        "MANIFEST.SKIP": "file://MANIFEST.SKIP"
    }

The file pointed to has to be available in: `$HOME/.config/yak/files`

Then `yak` can calculate the checksum dynamically, based on the reference file and can based on invocation copy the reference file to the location of the evaluated file in the case where the two differ.

## CHECKSUM DATA FILE EXAMPLE

This JSON file should be created as `$HOME/.config/yak/checksums.json`.

    {
        "CODE_OF_CONDUCT.md": "da9eed24b35eed80ce28e07b02725dbb356cfa56500a1552a1410ab5c73af82c",
        "CONTRIBUTING.md": "file://CONTRIBUTING.md",
        "PULL_REQUEST_TEMPLATE.md": "91dabee84afd46f93894d1a266a773f3d46c2c0b1ae4813f0c7dba34df1dc260",
        "MANIFEST.SKIP": "file://MANIFEST.SKIP"
    }

# INVOCATION

`yak` takes the following command line arguments:

- `--verbose`, enables more verbose output, can be configured see ["CONFIGURATION"](#configuration)
- `--silent`, disables output and you have to rely on the return value see ["RETURN\_VALUES"](#return_values) below.
- `--debug`, enables debug output. can be configured see ["CONFIGURATION"](#configuration)
- `--nodebug`, disables debug output even if confgured or provided as `--debug`, see above
- `--noconfig`, disables reading of the configuration file, (see ["CONFIGURATION"](#configuration)) and you have to rely on the command line arguments
- `--nochecksums`, disables reading of the global checksums file (see ["DATA\_SOURCE"](#data_source))
- `--about`, emits output on configuration and invocation and terminates with success.

Command line arguments override the configuration.

## RETURN VALUES

- `0`, success, everything is okay
- `1`, failure, a located filed did not match the designated checksum

Note that `--about` return as success with out processing any data apart from reading configuration and parsing command line arguments.

# CONFIGURATION

`$HOME/.config/yak/config.yml`

`yak` can be configured using the following paramters:

- `verbose`, which enables more verbose output
- `debug`, which enables debug output

Configuration can be overridden by command line arguments, see ["INVOCATION"](#invocation).

## EXAMPLE CONFIGURATION

This YAML file should be created as `$HOME/.config/yak/config.yml`.

    verbose: false
    debug: false

# DATA SOURCE

The default data source is described in the ["DESCRIPTION"](#description). As a an alternative a per project file can be specified in the designated repository/directory.

The file should be named: `.yaksums.json`

The contents follow the same format as the `$HOME/.config/yak/checksums.json`.

This JSON file should look as follows:

    {
        "<filename>": "<sha256 checksum for the file specifed by the filename>"
    }

An example:

    {
        "CODE_OF_CONDUCT.md": "da9eed24b35eed80ce28e07b02725dbb356cfa56500a1552a1410ab5c73af82c",
        "CONTRIBUTING.md": "file://CONTRIBUTING.md",
        "PULL_REQUEST_TEMPLATE.md": "91dabee84afd46f93894d1a266a773f3d46c2c0b1ae4813f0c7dba34df1dc260",
        "MANIFEST.SKIP": "file://MANIFEST.SKIP"
    }

# USING DOCKER

An experimental Docker implementation has been included with the repository.

It can be built using the following statement:

    $ docker build -t jonasbn/yak .

And then run as follows:

    $ docker run --rm -it -v $PWD:/tmp jonasbn/yak

It will consume all the command line arguments (see ["INVOCATION"](#invocation)).

The Docker image has the following command line arguments embedded:

- `--noconfig`
- `--nochecksums`

Since the ability to read files outside the Docker container is limited to the directory mounted.

The mount point is expected to be a directory containing the files to be checked against the checksum data structure. Please see the ["LIMITATIONS"](#limitations) for details.

# LIMITATIONS

- Running under Docker is limited to using only checksums specified in a local <.yaksums.json> and configuration has to be specified using command line arguments not a file
- The use of a local: `.yaksums.json` is limited to checksums and cannot calculate based on files, since files are located in an unmounted directory

# ISSUE REPORTING

If you experience any issues with `yak` report these via GitHub. Please read  [the issue reporting template](https://github.com/jonasbn/yak/blob/master/.github/ISSUE_TEMPLATE.md).

# DEVELOPMENT

If you want to contribute to `yak` please read the [Contribution guidelines](https://github.com/jonasbn/yak/blob/master/CONTRIBUTING.md)
and follow [the pull request guidelines](https://github.com/jonasbn/yak/blob/master/.github/PULL_TEMPLATE.md).

# MOTIVATION

Much of what I do is yak shaving. For you who are not familiar with the term:

    "[MIT AI Lab, after 2000: orig. probably from a Ren & Stimpy episode.]
    Any seemingly pointless activity which is actually necessary to solve
    a problem which solves a problem which, several levels of recursion
    later, solves the real problem you're working on."

REF: [The Jargon File](http://www.catb.org/~esr/jargon/html/Y/yak-shaving.html)

Used commonly for repetive and boring work, required to reach a certain goal.

# AUTHOR

- jonasbn <jonasbn@cpan.org>

# COPYRIGHT

`yak` is (C) by Jonas B. Nielsen, (jonasbn) 2018-2020

Image used on the `yak` [website](https://jonasbn.github.io/yak/) is under copyright by [Shane Aldendorff](https://unsplash.com/photos/3b3O75X0Jzg)

# LICENSE

`yak` is released under the MIT License
