#!perl

use Test2::Bundle::Extended;

use lib 't/lib';

use Data::Record::Serialize;

eval 'use DBI; 1'
  or plan skip_all => "Need DBI to run the DBI backend tests\n";

eval 'use DBD::SQLite; 1'
  or plan skip_all => "Need DBD::SQLite to run the DBI backend tests\n";

sub tmpfile {

    require File::Temp;

    # *BSD systems need EXLOCK=>0 to prevent lock contention (see docs
    # for File::Temp)
    return File::Temp->new( @_, EXLOCK => 0 );

}


my @test_data = (

    { a => 1, b => 2, c => 'nyuck nyuck' },
    { a => 3, b => 4, c => 'niagara falls' },
    { a => 5, b => 6, c => 'why youuu!' },
    { a => 7, b => 8, c => 'scale that fish!' },

);

# just in case we corrupt @test_data;
my $test_data_nrows = @test_data;

subtest 'autocommit' => sub {

    my $db = tmpfile();
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => 1,
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );

};



subtest 'transaction rows == batch' => sub {

    my $db = tmpfile();
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => $test_data_nrows,
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( {%$_} ) foreach @test_data;

    # dig beyond API to make sure that autocommit was really off _dbh
    # isn't generated until the first send, so must do this check
    # after that.
    ok( !$s->_dbh->{AutoCommit}, "Ensure that AutoCommit is really off" );

    undef $s;

    test_db( $db );
};

subtest 'transaction rows < batch' => sub {

    my $db = tmpfile();
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => $test_data_nrows + 1,
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );
};

subtest 'transaction rows > batch' => sub {

    my $db = tmpfile();
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'dbi',
                dsn    => [ 'SQLite', { dbname => $db->filename } ],
                table  => 'test',
                batch  => $test_data_nrows - 1,
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );
};

subtest 'drop table' => sub {

    my $db = tmpfile();
    my $s;

    my $dbh;
    ok(
        lives {
            $dbh = DBI->connect( "dbi:SQLite:dbname=@{[ $db->filename ]}",
                '', '', { RaiseError => 1 } );
        },
        'open sqlite db file'
    ) or diag $@;

    ok(
        lives {
            $dbh->do( 'create table test ( foo real )' );
        },
        'create table'
    ) or diag $@;
    $dbh->disconnect;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode     => 'dbi',
                dsn        => [ 'SQLite', { dbname => $db->filename } ],
                table      => 'test',
                batch      => $test_data_nrows - 1,
                drop_table => 1,
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( {%$_} ) foreach @test_data;

    undef $s;

    test_db( $db );
};



sub test_db {

    my $ctx = context;

    my ( $db, $nrows ) = @_;

    $nrows ||= $test_data_nrows;

    my $dbh;
    my @rows;

    ok(
        lives {
            $dbh = DBI->connect( "dbi:SQLite:dbname=@{[ $db->filename ]}",
                '', '', { RaiseError => 1 } );
        },
        'open created sqlite db file'
    ) or diag $@;

    my $sth;
    my $rows;
    ok(
        lives {
            $rows = $dbh->selectall_arrayref( 'select * from test',
                { Slice => {} } );
        },
        'select rows from file',
    ) or diag $@;

    is( scalar @$rows, $test_data_nrows, 'correct number of rows' );

    is( $rows->[$_], $test_data[$_],
        "row[$_]: stored data eq passed data" )
      foreach 0 .. $#test_data;

    $ctx->release;
}

done_testing;
