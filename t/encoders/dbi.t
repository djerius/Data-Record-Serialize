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


my @test_data = (

    { a => 1, b => 2, c => 'nyuck nyuck' },
    { a => 3, b => 4, c => 'niagara falls' },
    { a => 5, b => 6, c => 'why youuu!' },
    { a => 7, b => 8, c => 'scale that fish!' },

);

# just in case we corrupt @test_data;
my $test_data_nrows = @test_data;

subtest 'autocommit' => sub {

    my $db = File::Temp->new;
    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => 1,
            );
        },
        undef,
        "constructor"
    );

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );

};



subtest 'transaction rows == batch' => sub {

    my $db = File::Temp->new;
    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => $test_data_nrows,
            );
        },
        undef,
        "constructor"
    );

    $s->send( {%$_} ) foreach @test_data;

    # dig beyond API to make sure that autocommit was really off _dbh
    # isn't generated until the first send, so must do this check
    # after that.
    ok( !$s->_dbh->{AutoCommit}, "Ensure that AutoCommit is really off" );

    undef $s;

    test_db( $db );
};

subtest 'transaction rows < batch' => sub {

    my $db = File::Temp->new;
    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => $test_data_nrows + 1,
            );
        },
        undef,
        "constructor"
    );

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );
};

subtest 'transaction rows > batch' => sub {

    my $db = File::Temp->new;
    my $s;

    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => $test_data_nrows - 1,
            );
        },
        undef,
        "constructor"
    );

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );
};



sub test_db {

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ( $db, $nrows ) = @_;

    $nrows ||= $test_data_nrows;

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

    is( scalar @$rows, $test_data_nrows, 'correct number of rows' );

    is_deeply( $rows->[$_], $test_data[$_],
        "row[$_]: stored data eq passed data" )
      foreach 0 .. $#test_data;

}

done_testing;
