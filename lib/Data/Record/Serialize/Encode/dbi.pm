package Data::Record::Serialize::Encode::dbi;

# ABSTRACT:  store a record in a database

use Moo::Role;

our $VERSION = '0.09';

use Data::Record::Serialize::Types -types;

use SQL::Translator;
use SQL::Translator::Schema;
use Types::Standard -types;

use List::Util qw[ pairmap ];

use DBI;
use Carp;

use namespace::clean;

=attr C<dsn>

I<Required> The DBI Data Source Name (DSN) passed to B<L<DBI>>.  It
may either be a string or an arrayref containing strings or arrayrefs,
which should contain key-value pairs.  Elements in the sub-arrays are
joined with C<=>, elements in the top array are joined with C<:>.  For
example,

  [ 'SQLite', { dbname => $db } ]

is transformed to

  SQLite:dbname=$db

The standard prefix of C<dbi:> will be added if not present.

=cut

has dsn => (
    is       => 'ro',
    required => 1,
    coerce   => sub {

        my $arg = 'ARRAY' eq ref $_[0] ? $_[0] : [ $_[0] ];
        my @dsn;
        for my $el ( @{$arg} ) {

            my $ref = ref $el;
            push( @dsn, $el ), next
              unless $ref eq 'ARRAY' || $ref eq 'HASH';

            my @arr = $ref eq 'ARRAY' ? @{$el} : %{$el};

            push @dsn, pairmap { join( '=', $a, $b ) } @arr;
        }

        unshift @dsn, 'dbi' unless $dsn[0] =~ /^dbi/;

        return join( ':', @dsn );
    },
);

=attr C<table>

I<Required> The name of the table in the database which will contain the records.
It will be created if it does not exist.

=cut

has table => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr C<drop_table>

If true, the table is dropped and a new one is created.

=cut

has drop_table => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


=attr C<create_table>

If true, a table will be created if it does not exist.

=cut

has create_table => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

=attr C<primary>

A single output column name or an array of output column names which
should be the primary key(s).  If not specified, no primary keys are
defined.

=cut

has primary => (
    is      => 'ro',
    isa     => ArrayOfStr,
    coerce  => 1,
    default => sub { [] },
);

=attr C<db_user>

The name of the database user

=cut

has db_user => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

=attr C<db_pass>

The database password

=cut

has db_pass => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has _sth => (
    is       => 'rwp',
    init_arg => undef,
);
has _dbh => (
    is       => 'rwp',
    init_arg => undef,
);

has column_defs => (
    is       => 'rwp',
    lazy     => 1,
    clearer  => 1,
    init_arg => undef,
    builder  => sub {

        my $self = shift;

        my @column_defs;
        for my $field ( @{ $self->output_fields } ) {

            push @column_defs,
              join( ' ',
                $field,
                $self->output_types->{$field},
                ( 'primary key' ) x !!( $self->primary eq $field ) );
        }

        return join ', ', @column_defs;
    },

);

=attr C<batch>

The number of rows to write to the database at once.  This defaults to 100.

If greater than 1, C<batch> rows are cached and then sent out in a
single transaction.  See L</Performance> for more information.

=cut

has batch => (
    is      => 'ro',
    isa     => Int,
    default => 100,
    coerce  => sub { $_[0] > 1 ? $_[0] : 0 },
);

=attr C<dbitrace>

A trace setting passed to  L<B<DBI>>.

=cut

has dbitrace => ( is => 'ro', );

has _cache => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
);

before BUILD => sub {

    my $self = shift;

    $self->_set__map_types( {
        S => 'text',
        N => 'real',
        I => 'integer'
    } );

    $self->_set__use_integer( 1 );
    $self->_set__need_types( 1 );

};

sub _table_exists {

    my $self = shift;

    # ignore catalogue and schema out of sheer ignorance, and the fact
    # that I'm not alone in that ignorance.

    return
      defined $self->_dbh->table_info( '%', '%', $self->table, 'TABLE' )->fetch;

}

=begin pod_coverage

=head3  setup

=end pod_coverage

=cut

my %producer = (
    DB2       => 'DB2',
    MySQL     => 'mysql',
    Oracle    => 'Oracle',
    Pg        => 'PostgreSQL',
    SQLServer => 'SQLServer',
    SQLite    => 'SQLite',
    Sybase    => 'Sybase',
);

sub setup {

    my $self = shift;

    return if $self->_dbh;

    my @dsn = DBI->parse_dsn( $self->dsn )
      or croak( "unable to parse DSN: ", $self->dsn );
    my $dbi_driver = $dsn[1];

    my $producer =  $producer{$dbi_driver} || $dbi_driver;

    my %attr       = (
        AutoCommit => !$self->batch,
        RaiseError => 1,
    );

    $attr{sqlite_allow_multiple_statements} = 1
      if $dbi_driver eq 'SQLite';

    $self->_set__dbh(
                     DBI->connect( $self->dsn, $self->db_user, $self->db_pass, \%attr )
                    )
      or croak( 'error connection to ', $self->dsn, "\n" );

    $self->_dbh->trace( $self->dbitrace )
      if $self->dbitrace;

    if ( $self->drop_table || ( $self->create_table && !$self->_table_exists ) )
    {
        my $tr = SQL::Translator->new(
            from => sub {
                my $schema = $_[0]->schema;
                my $table = $schema->add_table( name => $self->table )
                  or croak $schema->error;

                for my $field_name ( @{ $self->output_fields } ) {

                    $table->add_field(
                        name      => $field_name,
                        data_type => $self->output_types->{$field_name}
                    ) or croak $table->error;
                }

                if ( @{ $self->primary } ) {
                    $table->primary_key( @{ $self->primary } )
                      or croak $table->error;
                }

                1;
            },
            to             => $producer,
            producer_args  => { no_transaction => 1 },
            add_drop_table => $self->drop_table && $self->_table_exists,
        );


        my $sql = $tr->translate
          or croak $tr->error;

        # print STDERR $sql;
        eval { $self->_dbh->do( $sql ); };

        croak( "error in table creation: $@:\n$sql\n" )
          if $@;

        $self->_dbh->commit if $self->batch;
    }

    my $sql = sprintf(
        "insert into %s (%s) values (%s)",
        $self->table,
        join( ',', @{ $self->output_fields } ),
        join( ',', ( '?' ) x @{ $self->output_fields } ),
    );

    $self->_set__sth( $self->_dbh->prepare( $sql ) );

    return;
}

sub _empty_cache {

    my $self = shift;

    eval {
        $self->_sth->execute( @$_ ) foreach @{ $self->_cache };
        $self->_dbh->commit;
    };

    # don't bother rolling back aborted transactions;
    # individual inserts are independent of each other.
    croak "Transaction aborted: $@" if $@;

    @{ $self->_cache } = ();

    return;
}

=begin pod_coverage

=head3 send

=end pod_coverage

=cut

sub send {

    my $self = shift;

    if ( $self->batch ) {

        push @{ $self->_cache }, [ @{ $_[0] }{ @{ $self->output_fields } } ];

        $self->_empty_cache
          if @{ $self->_cache } == $self->batch;

    }
    else {
        $self->_sth->execute( @{ $_[0] }{ @{ $self->output_fields } } );
    }

}


after '_trigger_output_fields' => sub {
    $_[0]->clear_column_defs;
};

after '_trigger_output_types' => sub {
    $_[0]->clear_column_defs;
};


=begin pod_coverage

=head3 cleanup

=end pod_coverage

=cut

sub cleanup {

    my $self = shift;

    $self->_empty_cache
      if $self->batch;

    $self->_dbh->disconnect;
}

# these are required by the Sink/Encode interfaces but should never be
# called in the ordinary run of things.

=begin pod_coverage

=head3 say

=head3 print

=head3 encode

=end pod_coverage

=cut


sub say { croak }
sub print { croak }
sub encode { croak }

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';


1;


__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'sqlite', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::dbi> writes a record to a database using
L<B<DBI>>.

It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
L<B<Data::Record::Serialize::Role::Sink>> roles.

B<You cannot construct this directly; you must use
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.>

=head2 Types

Field types are recognized and converted to SQL types via the following map:

  S => 'text'
  N => 'real'
  I => 'integer'


=head2 Performance

Records are by default written to the database in batches (see the
C<batch> attribute) to improve performance.  Each batch is performed
as a single transaction.  If there is an error during the transaction,
record insertions during the transaction are I<not> rolled back.

=head1 ATTRIBUTES

These attributes are available in addition to the standard attributes
defined for L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
