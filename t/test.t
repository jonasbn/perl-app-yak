use Test2::V0;
use Test::Script;

# REF: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
use Env qw($CONTINUOUS_INTEGRATION);

script_compiles('script/yak');

if ($CONTINUOUS_INTEGRATION and $CONTINUOUS_INTEGRATION eq 'true') {
    script_runs(['script/yak', '--about', '--noconfig', '--nochecksums'], '"yak --about --noconfig --nochecksums" run');
} else {
    script_runs(['script/yak', '--about'], { exit => 0 }, '"yak --about" run');

    script_runs(['script/yak', '--help'], { exit => 0 }, '"yak --help" run');
    script_stdout_like qr{yak : v\d+\.\d+\.\d+}, 'We are looking for a version string';
    script_stdout_like qr{Usage: yak \[options\]}, 'We are looking for a usage message';
    script_stdout_like qr{Options:}, 'We are looking for a options heading';
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

    script_runs(['script/yak', '--version'], { exit => 0 }, '"yak --version" run');
    script_stdout_like qr{yak : v\d+\.\d+\.\d+}, 'We are looking for a version string';

    script_runs(['script/yak', '--debug'], { exit => 0 }, '"yak --debug" run');
    script_runs(['script/yak', '--nodebug'], { exit => 0 }, '"yak --nodebug" run');
    script_runs(['script/yak', '--verbose'], { exit => 0 }, '"yak --verbose" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--noconfig'], { exit => 0 }, '"yak --noconfig" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--config', 'examples/config.yml'], '"yak --config examples/config.yml" run');

    script_runs(['script/yak', '--silent'], { exit => 0 }, '"yak --silent" run');
    script_stdout_is '', 'We run in silence so no output';

    script_runs(['script/yak', '--nochecksums'], '"yak --nochecksums" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md failed}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--checksums', 'examples/checksums.json'], '"yak --checksums examples/checksums.json" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--checksums', 'https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json'], '"yak --checksums https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--color'], '"yak --color" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--nocolor'], '"yak --nocolor" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--emoji'], '"yak --emoji" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';

    script_runs(['script/yak', '--noemoji'], '"yak --noemoji" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md succeeded}, 'We cherry-pick from the output';
}

done_testing();
