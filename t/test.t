use Test2::V0;
use Test::Script;

# REF: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
use Env qw($CONTINUOUS_INTEGRATION);

script_compiles('yak');

if ($CONTINUOUS_INTEGRATION and $CONTINUOUS_INTEGRATION eq 'true') {
    script_runs(['yak', '--about', '--noconfig', '--nochecksums'], '"yak --about --noconfig --nochecksums" run');
} else {
    script_runs(['yak', '--about'], { exit => 0 }, '"yak --about" run');
    script_runs(['yak', '--help'], { exit => 0 }, '"yak --help" run');
    script_runs(['yak', '--debug'], '"yak --debug" run');
    script_runs(['yak', '--nodebug'], '"yak --nodebug" run');
    script_runs(['yak', '--verbose'], '"yak --verbose" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md}, 'We run with verbosity so plenty of output';
    script_runs(['yak', '--noconfig'], '"yak --noconfig" run');
    script_runs(['yak', '--config', 'examples/config.yml'], '"yak --config examples/config.yml" run');
    script_runs(['yak', '--silent'], { exit => 0 }, '"yak --silent" run');
    script_stdout_is '', 'We run in silence so no output';
    script_runs(['yak', '--nochecksums'], '"yak --nochecksums" run');
    script_runs(['yak', '--checksums', 'examples/checksums.json'], '"yak --checksums examples/checksums.json" run');
    script_runs(['yak', '--color'], '"yak --color" run');
    script_runs(['yak', '--nocolor'], '"yak --nocolor" run');
    script_runs(['yak', '--emoji'], '"yak --emoji" run');
    script_runs(['yak', '--noemoji'], '"yak --noemoji" run');
}

done_testing;
