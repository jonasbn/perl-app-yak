use Test2::V0;
use Test::Script;

# REF: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables
use Env qw($CONTINUOUS_INTEGRATION);

script_compiles('yak');

if ($CONTINUOUS_INTEGRATION eq 'true') {
    script_runs(['yak', '--about', '--noconfig'], '"yak --about" runs');
} else {
    script_runs(['yak', '--about'], '"yak --about" runs');
}

done_testing;
