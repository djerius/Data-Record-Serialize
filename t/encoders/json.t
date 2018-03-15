#!perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

use JSON::MaybeXS;

my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'json',
            output => \$buf,
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
$s->send( { a => 1, b => 2 } );

my @VAR1;

ok( lives { @VAR1 = JSON->new->incr_parse( $buf ) }, 'deserialize record', ) or diag $@;

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
    ],
    'properly formatted'
);

done_testing;
