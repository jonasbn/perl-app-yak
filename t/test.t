use Test2::V0;
use Test::Script;

# REF: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
use Env qw($CONTINUOUS_INTEGRATION);

script_compiles('yak');

if ($CONTINUOUS_INTEGRATION and $CONTINUOUS_INTEGRATION eq 'true') {
    script_runs(['yak', '--about', '--noconfig', '--nochecksums'], '"yak --about --noconfig --nochecksums" runs');
} else {
    script_runs(['yak', '--about'], '"yak --about" runs');
    script_runs(['yak', '--help'], '"yak --help" runs');
    script_runs(['yak', '--debug'], '"yak --debug" runs');
    script_runs(['yak', '--nodebug'], '"yak --nodebug" runs');
    script_runs(['yak', '--verbose'], '"yak --verbose" runs');
    script_runs(['yak', '--noconfig'], '"yak --noconfig" runs');
    script_runs(['yak', '--config', 'examples/config.yml'], '"yak --config examples/config.yml" runs');
    script_runs(['yak', '--silent'], '"yak --silent" runs');
    script_runs(['yak', '--nochecksums'], '"yak --nochecksums" runs');
    script_runs(['yak', '--checksums', 'examples/checksums.json'], '"yak --checksums examples/checksums.json" runs');
    script_runs(['yak', '--color'], '"yak --color" runs');
    script_runs(['yak', '--nocolor'], '"yak --nocolor" runs');
    script_runs(['yak', '--emoji'], '"yak --emoji" runs');
    script_runs(['yak', '--noemoji'], '"yak --noemoji" runs');
}

done_testing;
