use Test2::V0;
use Test::Script;

# CONTINUOUS_INTEGRATION: set by GitHub Actions; runs a reduced smoke set.
# INTEGRATION_TEST: opt-in flag for tests that reach outside the repo
#   (file:// checksum refs needing ~/.config/yak/files/, network URLs,
#    or the default ~/.config/yak/config.yml and checksums.json).
#   Enable with: INTEGRATION_TEST=true carton exec prove -lv t/test.t
use Env qw($CONTINUOUS_INTEGRATION $INTEGRATION_TEST);

script_compiles('script/yak');

if ($CONTINUOUS_INTEGRATION and $CONTINUOUS_INTEGRATION eq 'true') {

    # Minimal CI smoke tests — fully self-contained, no $HOME dependencies.
    script_runs(
        ['script/yak', '--about', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --about" smoke run'
    );

    script_runs(
        ['script/yak', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --noconfig --checksums examples/checksums_local.json" smoke run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'smoke: checksum match reported';

    script_runs(
        ['script/yak', '--noconfig', '--nochecksums'],
        { exit => 0 },
        '"yak --noconfig --nochecksums" smoke run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md present}, 'smoke: presence check reported';

} else {

    # ----------------------------------------------------------------
    # Self-contained tests — always pass without any $HOME setup.
    # All use --noconfig and a local checksums file with no external refs.
    # ----------------------------------------------------------------

    script_runs(
        ['script/yak', '--about', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --about" run'
    );

    script_runs(
        ['script/yak', '--help', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --help" run'
    );
    script_stdout_like qr{yak : v\d+\.\d+\.\d+},             'We are looking for a version string';
    script_stdout_like qr{Usage: yak \[options\]},             'We are looking for a usage message';
    script_stdout_like qr{Options:},                           'We are looking for an options heading';
    script_stdout_like qr{--debug: output debug information};
    script_stdout_like qr{--nodebug: disabling debug output, if configured};
    script_stdout_like qr{--verbose: more verbose output};
    script_stdout_like qr{--noconfig: ignore \$HOME/.config/.yak/config.yml};
    script_stdout_like qr{--config <file>: specify alternative to \$HOME/.config/.yak/config.yml};
    script_stdout_like qr{--silent: suppress all output and rely on return value};
    script_stdout_like qr{--nochecksums: ignore \$HOME/.config/.yak/checksums.json and use local .yaksums};
    script_stdout_like qr{--checksums <file>: specify alternative to \$HOME/.config/.yak/checksums.json};
    script_stdout_like qr{--nocolor: disable colorized output};
    script_stdout_like qr{--color: enable colorized output};
    script_stdout_like qr{--noemoji: disable emoji output};
    script_stdout_like qr{--emoji: enable emoji output};
    script_stdout_like qr{--about: emit configuration and invocation description};

    script_runs(
        ['script/yak', '--version', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --version" run'
    );
    script_stdout_like qr{yak : v\d+\.\d+\.\d+}, 'We are looking for a version string';

    script_runs(
        ['script/yak', '--debug', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --debug" run'
    );
    script_runs(
        ['script/yak', '--nodebug', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --nodebug" run'
    );

    script_runs(
        ['script/yak', '--verbose', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --verbose" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md}, 'We cherry-pick from the output';

    script_runs(
        ['script/yak', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --noconfig --checksums examples/checksums_local.json" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

    script_runs(
        ['script/yak', '--config', 'examples/config.yml', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --config examples/config.yml" run'
    );

    script_runs(
        ['script/yak', '--silent', '--noconfig', '--checksums', 'examples/checksums_local.json'],
        { exit => 0 },
        '"yak --silent" run'
    );
    script_stdout_is '', 'We run in silence so no output';

    script_runs(
        ['script/yak', '--noconfig', '--nochecksums'],
        { exit => 0 },
        '"yak --noconfig --nochecksums" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md present}, 'We cherry-pick from the output';

    script_runs(
        ['script/yak', '--noconfig', '--checksums', 'examples/checksums_local.json', '--color'],
        { exit => 0 },
        '"yak --color" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

    script_runs(
        ['script/yak', '--noconfig', '--checksums', 'examples/checksums_local.json', '--nocolor'],
        { exit => 0 },
        '"yak --nocolor" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

    script_runs(
        ['script/yak', '--noconfig', '--checksums', 'examples/checksums_local.json', '--emoji'],
        { exit => 0 },
        '"yak --emoji" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

    script_runs(
        ['script/yak', '--noconfig', '--checksums', 'examples/checksums_local.json', '--noemoji'],
        { exit => 0 },
        '"yak --noemoji" run'
    );
    script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

    # false assertion: file IS present → should fail and report "present"
    script_runs(
        ['script/yak', '--noconfig', '--noemoji', '--nocolor', '--checksums', 'examples/checksums_false_present.json'],
        { exit => 1 },
        '"yak" exits 1 when false-asserted file exists'
    );
    script_stdout_like qr{CODE_OF_CONDUCT\.md present}, 'false assertion on present file emits "present" failure';

    # false assertion: file IS absent → should succeed and report "not present"
    script_runs(
        ['script/yak', '--noconfig', '--noemoji', '--nocolor', '--checksums', 'examples/checksums_false_absent.json'],
        { exit => 0 },
        '"yak" exits 0 when false-asserted file is absent'
    );
    script_stdout_like qr{nonexistent-sentinel-yak-test\.xyz not present}, 'false assertion on absent file emits "not present" success';

    # ----------------------------------------------------------------
    # Integration tests — require external resources.
    # Enable with: INTEGRATION_TEST=true carton exec prove -lv t/test.t
    # ----------------------------------------------------------------
    if ($INTEGRATION_TEST and $INTEGRATION_TEST eq 'true') {

        # Needs ~/.config/yak/files/CONTRIBUTING.md and MANIFEST.SKIP
        script_runs(
            ['script/yak', '--noconfig', '--checksums', 'examples/checksums.json'],
            { exit => 0 },
            '"yak --checksums examples/checksums.json" run (file:// refs)'
        );
        script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

        # Needs network access and a live URL
        script_runs(
            ['script/yak', '--noconfig', '--checksums', 'https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json'],
            { exit => 0 },
            '"yak --checksums https://..." run (network)'
        );
        script_stdout_like qr{./CODE_OF_CONDUCT.md matches}, 'We cherry-pick from the output';

        # Needs ~/.config/yak/config.yml and ~/.config/yak/checksums.json
        script_runs(
            ['script/yak', '--about'],
            { exit => 0 },
            '"yak --about" run (default config from $HOME)'
        );
    }
}

done_testing();
