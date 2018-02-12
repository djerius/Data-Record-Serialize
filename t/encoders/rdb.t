#!perl

use Test2::V0;

use lib 't/lib';

use Data::Record::Serialize;

use JSON::MaybeXS qw[ decode_json ];

my ( $s, $buf );

ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'rdb',
            output => \$buf,
            fields => [ qw( a b c d ) ],
          ),
          ;
    },
    "constructor"
) or diag $@;

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );

is( $buf, <<'END', 'properly formatted' );
a	b	c	d
N	N	S	S
1	2	nyuck nyuck	
END

done_testing;
