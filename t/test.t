use Test2::V0;
use Test::Script;

# REF: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
use Env qw($CONTINUOUS_INTEGRATION);

script_compiles('yak');

if ($CONTINUOUS_INTEGRATION and $CONTINUOUS_INTEGRATION eq 'true') {
    script_runs(['yak', '--about', '--noconfig', '--nochecksums'], '"yak --about --noconfig --nochecksums" run');
} else {
    script_runs(['yak', '--about'], '"yak --about" run');
    script_runs(['yak', '--help'], '"yak --help" run');
    script_runs(['yak', '--debug'], '"yak --debug" run');
    script_runs(['yak', '--nodebug'], '"yak --nodebug" run');
    script_runs(['yak', '--verbose'], '"yak --verbose" run');
    script_runs(['yak', '--noconfig'], '"yak --noconfig" run');
    script_runs(['yak', '--config', 'examples/config.yml'], '"yak --config examples/config.yml" run');
    script_runs(['yak', '--silent'], '"yak --silent" run');
    script_runs(['yak', '--nochecksums'], '"yak --nochecksums" run');
    script_runs(['yak', '--checksums', 'examples/checksums.json'], '"yak --checksums examples/checksums.json" run');
    script_runs(['yak', '--color'], '"yak --color" run');
    script_runs(['yak', '--nocolor'], '"yak --nocolor" run');
    script_runs(['yak', '--emoji'], '"yak --emoji" run');
    script_runs(['yak', '--noemoji'], '"yak --noemoji" run');
}

done_testing;
