#!perl

use Test::More;
use Test::Fatal;

use lib 't/lib';

use Data::Dumper;
use Data::Record::Serialize;

use lib 't/lib';


subtest "format fields" => sub {

    my ( $s, $buf );

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode        => 'ddump',
                output        => \$buf,
                format_fields => {
                    a => 'aAa: %s',
                    b => 'bBb: %s',
                },
            );
        },
        undef,
        "constructor"
    );

    $s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply(
        $VAR1,
        {
            a => 'aAa: 1',
            b => 'bBb: 2',
	    c => 'nyuck nyuck',
        },
        'properly formatted'
    );

};

subtest "format types" => sub {

    my ( $s, $buf );

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode        => 'ddump',
                output        => \$buf,
	        types => { a => 'N',
			   b => 'I',
			   c => 'S',
			 },
                format_types => {
                    N => 'number',
                    I => 'integer',
                    S => 'string',
                },
            );
        },
        undef,
        "constructor"
    );

    $s->send( { a => 1, b => 2, c => 3 } );

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply(
        $VAR1,
        {
            a => 'number',
            b => 'integer',
	    c => 'string',
        },
        'properly formatted'
    );

};

subtest "format types w/o specifying them" => sub {

    my ( $s, $buf );

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode        => 'ddump',
                output        => \$buf,
                format_types => {
                    N => 'number',
                    I => 'integer',
                    S => 'string',
                },
            );
        },
        undef,
        "constructor"
    );

    $s->send( { a => 1.1, b => 2, c => 'nyuck' } );

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply(
        $VAR1,
        {
            a => 'number',
            b => 'integer',
	    c => 'string',
        },
        'properly formatted'
    );

};

subtest "format fields overrides types" => sub {

    my ( $s, $buf );

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode        => 'ddump',
                output        => \$buf,
	        types => { a => 'N',
			   b => 'I',
			   c => 'S',
			 },
                format_types => {
                    N => 'number',
                    I => 'integer',
                    S => 'string',
                },
                format_fields => {
                    a => 'aAa: %s',
                    b => 'bBb: %s',
                },
            );
        },
        undef,
        "constructor"
    );

    $s->send( { a => 1, b => 2, c => 3 } );

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply(
        $VAR1,
        {
            a => 'aAa: 1',
            b => 'bBb: 2',
	    c => 'string',
        },
        'properly formatted'
    );

};


done_testing;
