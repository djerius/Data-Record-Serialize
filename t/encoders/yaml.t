#!perl

use Test::More;
use Test::Fatal;

use lib 't/lib';

use Data::Record::Serialize;

use lib 't/lib';

use YAML::Any qw[ Load ];

my ( $s, $buf );

is(
    exception {
        $s = Data::Record::Serialize->new(
            encode => 'yaml',
            output => \$buf,
          ),
          ;
    },
    undef,
    "constructor"
);

$s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );

my $VAR1;

is( exception { $VAR1 = Load( $buf ) },
    undef,
    'deserialize record' );

is_deeply(
    $VAR1,
    {
        a => '1',
        b => '2',
        c => 'nyuck nyuck',
    },
    'properly formatted'
);

done_testing;
