use Test2::V0;
use Test::Script;

script_compiles('yak');
script_runs(['yak', '--about'], '"yak --about" runs');

done_testing;
