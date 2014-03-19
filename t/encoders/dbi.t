#!perl

use Test::More;
use Test::Fatal;

use lib 't/lib';

use Data::Record::Serialize;

use File::Temp;
use Class::Load qw[ try_load_class ];

try_load_class( 'DBI' )
  or plan skip_all => "Need DBI to run the DBI backend tests\n";

try_load_class( 'DBD::SQLite' )
  or plan skip_all => "Need DBD::SQLite to run the DBI backend tests\n";


my $db = File::Temp->new;

{
    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
            );
        },
        undef,
        "constructor"
    );

    $s->send( { a => 1, b => 2, c => 'nyuck nyuck' } );
}

{

    my $dbh;
    my @rows;

    is(
        exception {
            $dbh = DBI->connect( "dbi:SQLite:dbname=@{[ $db->filename ]}",
                '', '', { RaiseError => 1 } );
        },
        undef,
        'open created sqlite db file'
    );

    my $sth;
    is(
        exception {
            $rows = $dbh->selectall_arrayref( 'select * from test',
                { Slice => {} } );
        },
        undef,
        'select rows from file',
    );

    is( scalar @$rows, 1, 'correct number of rows' );

    is_deeply(
        $rows->[0],
        {
            a => '1',
            b => '2',
            c => 'nyuck nyuck',
        },
        'stored data eq passed data'
    );

}

done_testing;
