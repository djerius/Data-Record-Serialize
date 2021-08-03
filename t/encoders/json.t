#!perl

use Test2::V0;

use Test::Lib;

use My::Test::Util -all;

use Data::Record::Serialize;

use JSON::MaybeXS;

my ( $s, $buf );

my @output;
ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode  => 'json',
            sink    => 'array',
            output  => \@output,
            nullify => ['string2'],
            fields  => [ 'integer', 'number', 'string1', 'string2', 'bool' ],
            types   => { bool => 'B' },
        );
    },
    "constructor"
) or diag $@;

my $json = JSON->new;

subtest 'record does not require transformation' => sub {

    # prime types
    $s->send( {
        integer => 1,
        number  => 2.2,
        string1 => 'string',
        string2 => 'nyuck nyuck'
    } );

    my $got;

    # read and make sure round trip types are correct
    ok( lives { $got = $json->incr_parse( $output[-1] ) },
        'deserialize record' )
      or diag $@;

    is(
        $got,
        hash {
            field integer => 1;
            field number  => 2.2;
            field string1 => 'string';
            field string2 => 'nyuck nyuck';
            end;
        },
        'round-trip values'
    );


  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest "output field values properly retained" => sub {
            ok( is_number( $got->{number} ),  'number' );
            ok( is_number( $got->{integer} ), 'integer' );
            ok( is_string( $got->{string1} ), 'string1' );
            ok( is_string( $got->{string2} ), 'string2' );
        };
    }

};

subtest 'record requires transformation' => sub {
    # now try something that needs numify & stringify
    $s->send( {
        integer => '1',
        number  => '2.2',
        string1 => 99,
        string2 => 'nyuck nyuck',
        bool    => 1
    } );

    my $got;

    ok( lives { $got = JSON->new->incr_parse( $output[-1] ) },
        'deserialize record' )
      or diag $@;

    is(
        $got,
        hash {
            field integer => 1;
            field number  => 2.2;
            field string1 => '99';
            field string2 => 'nyuck nyuck';
            field bool    => meta {
                prop this => in_set(
                    meta { prop blessed => 'JSON::PP::Boolean'; },
                    meta { prop blessed => 'Types::Serializer::Boolean'; },
                );
                prop this => 1;
            };
            end;
        },
        'round-trip values'
    );

  SKIP: {
        skip 'Need Convert::Scalar' unless $have_Convert_Scalar;
        subtest "output field values properly converted" => sub {
            ok( is_number( $got->{number} ),  'number' );
            ok( is_number( $got->{integer} ), 'integer' );
            ok( is_string( $got->{string1} ), 'string1' );
            ok( is_string( $got->{string2} ), 'string2' );
        };
    }
};

done_testing;
