#!perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

use YAML::Any qw[ Load ];

my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'yaml',
            output => \$buf,
            nullify => [ 'c' ],
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
$s->send( { a => 1, b => 2, } );
$s->send( { a => 1, b => 2, c => '' } );

my @VAR1;

ok( lives { @VAR1 = Load( $buf ) }, 'deserialize record', ) or diag $@;

is(
    \@VAR1,
    [ {
            a => '1',
            b => '2',
            c => 'nyuck nyuck',
        },
        {
            a => '1',
            b => '2',
        },
        {
            a => '1',
            b => '2',
            c => undef,
        },
    ],
    'properly formatted'
);

done_testing;
