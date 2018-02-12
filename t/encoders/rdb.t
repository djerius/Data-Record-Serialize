#!perl

use Test2::V0;
use Test2::Plugin::NoWarnings;

use lib 't/lib';

use Data::Record::Serialize;

use JSON::MaybeXS qw[ decode_json ];

my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'rdb',
            output => \$buf,
            fields => [ qw[ a b c ] ],
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
$s->send( { a => 1, b => 2 } );

is( $buf, <<'END', 'properly formatted' );
a	b	c
N	N	S
1	2	nyuck nyuck
1	2	
END

done_testing;
