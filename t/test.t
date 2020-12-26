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
    script_runs(['script/yak', '--version'], '"yak --version" run');
    script_runs(['script/yak', '--debug'], '"yak --debug" run');
    script_runs(['script/yak', '--nodebug'], '"yak --nodebug" run');
    script_runs(['script/yak', '--verbose'], '"yak --verbose" run');
    script_stdout_like qr{./CODE_OF_CONDUCT.md}, 'We run with verbosity so plenty of output';
    script_runs(['script/yak', '--noconfig'], '"yak --noconfig" run');
    script_runs(['script/yak', '--config', 'examples/config.yml'], '"yak --config examples/config.yml" run');
    script_runs(['script/yak', '--silent'], { exit => 0 }, '"yak --silent" run');
    script_stdout_is '', 'We run in silence so no output';
    script_runs(['script/yak', '--nochecksums'], '"yak --nochecksums" run');
    script_runs(['script/yak', '--checksums', 'examples/checksums.json'], '"yak --checksums examples/checksums.json" run');
    script_runs(['script/yak', '--checksums', 'https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json'], '"yak --checksums https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json" run');
    script_runs(['script/yak', '--color'], '"yak --color" run');
    script_runs(['script/yak', '--nocolor'], '"yak --nocolor" run');
    script_runs(['script/yak', '--emoji'], '"yak --emoji" run');
    script_runs(['script/yak', '--noemoji'], '"yak --noemoji" run');
}

done_testing;
