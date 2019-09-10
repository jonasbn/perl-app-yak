

:warning: WARNING! :warning:

This this project and it's components are WIP and \_alpha\_ software, everything is far from working and farther from finished

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

# CONFIGURATION

`yak` can be configured using the following paramters:

- `gitignore`, which enables the use of a local gitignore file

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

`yak` is (C) by Jonas B. Nielsen, (jonasbn) 2018-2019

Image used on the `yak` [website](https://jonasbn.github.io/yak/) is under copyright by [Shane Aldendorff](https://unsplash.com/photos/3b3O75X0Jzg)

# LICENSE

`yak` is released under the MIT License

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 82:

    &#x3d;end markdown without matching =begin.  (Stack: \[empty\])
