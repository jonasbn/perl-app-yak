[![Build Status](https://travis-ci.org/jonasbn/perl-app-yak.svg?branch=master)](https://travis-ci.org/jonasbn/yak)
![Spellcheck Action](https://github.com/jonasbn/perl-app-yak/workflows/Spellcheck%20Action/badge.svg)
![Markdownlint Action](https://github.com/jonasbn/perl-app-yak/workflows/Markdownlint%20Action/badge.svg)

The **yak** command line utility is still WIP and to be regarded as *alpha* software, most features are working but it not ready for first official release

---

# yak

**yak** - application to help with yak shaving for Git repositories etc.

# DESCRIPTION

The **yak** _shaver_ can scan a directory for files, which can be classified as yaks in need of shaving. Meaning files which are maintained else where are often copy-pasted.

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

## IGNORING CERTAIN DIRECTORIES, FILES AND FILENAME PATTERNS

`yak` supports the ability to ignore:

- Files
- Directories
- Filename patterns

This is accomplished using an implementation based on `.gitignore`. To not intervene and to let `git` and `yak` work in harmony. The files used by `yak` are named `.yakignore`.

The mean that you can:

- Specify patterns of files and directories in your configuration file, see ["CONFIGURATION"](#configuration). This configuration will be overwritten if the next options are used.
- You can add an `.yakignore` in the root of your repository and it will work for all files and directories in the file structure beneath it. Do note that the presence of this files, ignores and configuration in regard to using this feature. Meaning that disabling `yak` ignores for a single repository can be accomplished by placing an empty `.yakignore` file in the root of the repository.
- a _child_ `.yakignore` can be placed in a subsequent directory, working on all files and directories beneath it, do note that directories specified to be ignored in the _parent_ `.yakignore` are ignored and are not parsed and used.

## YAK IGNORE FILE EXAMPLE

    .git
    local

The above example specified the `local` directory created by Perl's Carton. Another good candidate could be the `.git` folder.

Since `yak` is processing a directory structure recursively, specifying directories should speed up the processing. Specifying single files by name can be used to skip a file specified in the data source file temporarily.

# INVOCATION

`yak` takes the following command line arguments:

- `--verbose`, enables more verbose output, can be configured see ["CONFIGURATION"](#configuration)
- `--silent`, disables output and you have to rely on the return value see ["RETURN VALUES"](#return-values) below.
- `--debug`, enables debug output. can be configured see ["CONFIGURATION"](#configuration)
- `--nodebug`, disables debug output even if confgured or provided as `--debug`, see above
- `--config file`, reads alternative configuration file instead of default, see ["CONFIGURATION"](#configuration)
- `--noconfig`, disables reading of the configuration file, (see ["CONFIGURATION"](#configuration)) and you have to rely on the command line arguments
- `--nochecksums`, disables reading of the global checksums file, see ["DATA SOURCE"](#data-source)
- `--checksums file`, reads alternative checksums file instead of default, see ["DATA SOURCE"](#data-source)
- `--color`, enables colorized output, enabled by default or can be configured, see ["CONFIGURATION"](#configuration)
- `--nocolor`, disables colorized output, even if confgured or provided as `--color`, see above
- `--emoji`, enables emojis in output, enabled by default or can be configured, see ["CONFIGURATION"](#configuration)
- `--noemoji`, disables emojis in output, even if confgured or provided as `--emoji`, see above
- `--about`, emits output on configuration and invocation and terminates with success
- `--help`, emits help message listing all available options

Command line arguments override the configuration.

## RETURN VALUES

- `0`, success, everything is okay
- `1`, failure, a located filed did not match the designated checksum

Note that `--about` return as success with out processing any data apart from reading configuration and parsing command line arguments.

# ENVIRONMENT

`yak` supports the following environment variables:

- `$CLICOLOR}`, if set to false (`0`) it attempts to disable colorized output, if set to true (`1`), it attempts to enable colorized output
- `$CLICOLOR_FORCE`, if set to true (`1`) it enables colorized output, if set to false (`1`), it disables colorized output

The order of precedence is as follows:

- 1. Environment (this section), `$CLICOLOR_FORCE`
- 2. Command line arguments, `--nocolor` and `--color` in that order, see ["INVOCATION"](#invocation)
- 3. Environment (this section), `$CLICOLOR`
- 4. Configuration, see ["CONFIGURATION"](#configuration), `color` configuration option

This aims to follow the proposed standard described in [this article](https://bixense.com/clicolors/).

# CONFIGURATION

`$HOME/.config/yak/config.yml`

`yak` can be configured using the following paramters:

- `verbose`, enabling (`true`) or disabling (`false`) more verbose output
- `debug`, enabling (`true`) or disabling (`false`) debug output
- `color`, enabling (`true`) or disabling (`false`) colorized output
- `emoji`, enabling (`true`) or disabling (`false`) colorized output
- `success_emoji`
- `failure_emoji`
- `skip_emoji`
- `yakignores`, specify a list of file directory names and patterns to be ignored

Configuration can be overridden by command line arguments, see ["INVOCATION"](#invocation).

## EXAMPLE CONFIGURATION

This YAML file should be created as `$HOME/.config/yak/config.yml`.

    verbose: false
    debug: false
    skip_emoji: ✖️
    failure_emoji: ❌
    success_emoji: ✅
    yakignores:
    - .git
    - local

# DATA SOURCE

There are 3 ways to provide checksum data to `yak`.

- The default using: `$HOME/.config/yak/checksums.json`, which can then be edited to match your needs
- Using a project or repository specific: `.yaksums.json` located in the root of your project or repository directory
- Using an JSON file adhering to formatting described in this chapter, which can be located elsewhere on your file system

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

Since the ability to read files outside the Docker container is limited to mounted directories.

The mount point is expected to be a directory containing the files to be checked against the checksum data structure. Please see the ["LIMITATIONS"](#limitations) for details.

If you want to utilize the supported environment variables (see ["ENVIRONMENT"](#environment)) you have to do something along the lines of:

    $ docker run --rm -it -v $PWD:/tmp --env CLICOLOR=$CLICOLOR jonasbn/yak

# REQUIREMENTS AND DEPENDENCIES

`yak` is specified to a minimum requirement of Perl 5.10, based on an analysis made using [Perl::MinimumVersion](https://metacpan.org/pod/Perl%3A%3AMinimumVersion), implementation syntax requires Perl 5.8.0, so `yak` _could be made to work_ for 5.8.0.

- [Crypt::Digest::SHA256](https://metacpan.org/pod/CryptX)
- [Data::Dumper](https://metacpan.org/pod/Data::Dumper)
- [Data::Stack](https://metacpan.org/pod/Data::Stack)
- [Env](https://metacpan.org/pod/Env)
- [File::Find](https://metacpan.org/pod/File::Find)
- [File::Slurper](https://metacpan.org/pod/File::Slurper)
- [Getopt::Long](https://metacpan.org/pod/Getopt::Long)
- [JSON](https://metacpan.org/pod/JSON)
- [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)
- [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor)
- [Text::Gitignore](https://metacpan.org/pod/Text::Gitignore)
- [YAML::Tiny](https://metacpan.org/pod/YAML::Tiny)

# LIMITATIONS

- `yak` is specified to a minimum requirement of Perl 5.10, based on an analysis made using [Perl::MinimumVersion](https://metacpan.org/pod/Perl%3A%3AMinimumVersion), implementation syntax requires Perl 5.8.0, so `yak` _could be made to work_ for 5.8.0.
- Running under Docker is limited to using only checksums specified in a local <.yaksums.json> and configuration has to be specified using command line arguments not a file
- The use of a local: `.yaksums.json` is limited to checksums and cannot calculate based on files, since files are located in an unmounted directory
- The use of YAML implementation is based on [YAML::Tiny](https://metacpan.org/pod/YAML::Tiny) and is therefor limited to this more simple implementation, which was however deemed sufficient for **Yak**.
- `yak` does currently not support symbolic links when doing file system traversal. The implementation is based on [File::Find](https://metacpan.org/pod/File::Find) and support for symbolic links could be enabled, but has not been regarded as necessary for now.
- The parsing of `.yakignore` files is based on [Text::Gitignore](https://metacpan.org/pod/Text::Gitignore) and is limited to what this implementation supports, no known issues at this time.

# ISSUE REPORTING

If you experience any issues with **yak** report these via GitHub. Please read [the issue reporting template](https://github.com/jonasbn/perl-app-yak/blob/master/.github/ISSUE_TEMPLATE.md).

# DEVELOPMENT

If you want to contribute to **yak** please read the [Contribution guidelines](https://github.com/jonasbn/perl-app-yak/blob/master/CONTRIBUTING.md)
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

- jonasbn, [website](https://jonasbn.github.io/)

# COPYRIGHT

`yak` is (C) by Jonas Brømsø, (jonasbn) 2018-2020

[Image](https://unsplash.com/photos/3b3O75X0Jzg) used on the **yak** [website](https://jonasbn.github.io/perl-app-yak/) is under copyright by [Shane Aldendorff](https://unsplash.com/@pluyar).

# LICENSE

`yak` is released under the MIT License

# REFERENCES

- 1. GitHub: ["The Yak Project"](https://jonasbn.github.io/yak/)
- 2. MetaCPAN: [TERM-ANSICOLOR](https://metacpan.org/pod/Term%3A%3AANSIColor)
- 3. Bixsense: ["Standard for ANSI Colors in Terminals"](https://bixense.com/clicolors/)
