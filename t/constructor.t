#!perl

use Test2::V0;

use Data::Record::Serialize;

use Test::Lib;

like(
    dies { Data::Record::Serialize->new },
    qr/must specify 'encode'/,
    'empty args'
);

like(
     dies {
         Data::Record::Serialize->new( encode => 'both',
                                       sink => 'stream' );
     },
     qr/don't specify a sink/,
     q[encode includes sink ; don't specify sink]
);


ok (
    lives {
         Data::Record::Serialize->new( encode => 'ddump',
                                       sink => 'stream' );
     },
    'encode + sink'
   ) or diag $@;

ok (
    lives {
         Data::Record::Serialize->new( encode => 'ddump');
     },
    'encode + default sink'
   ) or diag $@;

done_testing;
