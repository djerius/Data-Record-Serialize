package Data::Record::Serialize::Role::Base;

use Moo::Role;

our $VERSION = '0.15';

use Data::Record::Serialize::Error -all;

use Types::Standard qw[ ArrayRef CycleTuple HashRef Enum Str Bool is_HashRef Undef ];

use POSIX ();

use namespace::clean;

has types => (
    is        => 'rwp',
    isa       => HashRef [ Enum [qw( N I S )] ] | CycleTuple[ Str, Enum[ qw( N I S ) ] ],
    predicate => 1,
    trigger   => sub {
        $_[0]->clear_numeric_fields;
        $_[0]->clear_output_types;
    },
);

has default_type => (
    is  => 'ro',
    isa => Enum [qw( N I S )] | Undef,
);

# input field names;
has fields => (
    is      => 'rwp',
    isa     => ArrayRef [Str] | Enum ['all'],
    predicate => 1,
    clearer => 1,
    trigger => sub {
        $_[0]->_clear_fieldh;
        $_[0]->clear_output_types;
        $_[0]->clear_output_fields;
    },
);


# for quick lookup of field names
has _fieldh => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        my %fieldh;
        @fieldh{ @{ $self->fields } } = ( 1 ) x @{ $self->fields };
        return \%fieldh;
    },
);


# output field names
has output_fields => (
    is      => 'lazy',
    trigger => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        [ map { $self->rename_fields->{$_} // $_ } @{ $self->fields } ];
    },
    init_arg => undef,
);

sub _trigger_output_fields { }

has _run_setup => (
    is        => 'rwp',
    isa       => Bool,
    init_args => undef,
    default   => 1,
);

has _need_types => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 1,
);

has _use_integer => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 1,
    # just in case need_types isn't explicitly set...
    trigger => sub { $_[0]->_set__need_types( 1 ) },
);

has _needs_eol => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 1,
);

has _numify => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 0,
);

has numeric_fields => (
    is      => 'lazy',
    clearer => 1,
    builder => sub {
        my $self = shift;

        return [
            grep { $self->types->{$_} =~ /[IN]/i }
              keys %{ $self->types } ];

    },
    init_arg => undef,
);

has output_types => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    trigger  => 1,
    builder  => sub {
        my $self = shift;

        my %types;

        return unless $self->has_types;

        my @int_fields = grep { defined $self->types->{$_} } @{ $self->fields };
        @types{@int_fields} = @{ $self->types }{@int_fields};

        unless ( $self->_use_integer ) {
            $_ = 'N' foreach grep { $_ eq 'I' } values %types;
        }

        if ( $self->_has_map_types ) {

            $types{$_} = $self->_map_types->{ $types{$_} } foreach keys %types;

        }

        for my $key ( keys %types ) {

            my $rename = $self->rename_fields->{$key}
              or next;

            $types{$rename} = delete $types{$key};
        }

        \%types;
    },
);

sub _trigger_output_types { }

has _map_types => (
    is        => 'rwp',
    init_arg  => undef,
    predicate => 1,
);

has format_fields => (
    is  => 'ro',
    isa => HashRef [Str],
);

has format_types => (
    is  => 'ro',
    isa => HashRef [Str],
    # we'll need to gather types
    trigger => sub { $_[0]->_set__need_types( 1 ) if keys %{ $_[1] }; },
);


has rename_fields => (
    is     => 'ro',
    isa    => HashRef [Str],
    coerce => sub {
        return $_[0] unless is_HashRef( $_[0] );

        # remove renames which do nothing
        my %rename = %{ $_[0] };
        delete @rename{ grep { $rename{$_} eq $_ } keys %rename };
        return \%rename;
    },
    default => sub { {} },
    trigger => sub {
        $_[0]->clear_output_types;
    },
);


has format => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has _format => (
    is      => 'rwp',
    lazy    => 1,
    default => sub {

        my $self = shift;


        if ( $self->format ) {

            my %format;

            # first consider types; they'll be overridden by per field
            # formats in the next step.
            if ( $self->format_types && $self->types ) {

                for my $field ( @{ $self->fields } ) {

                    my $type = $self->types->{$field}
                      or next;

                    my $format = $self->format_types->{$type}
                      or next;

                    $format{$field} = $format;
                }
            }

            if ( $self->format_fields ) {

                for my $field ( @{ $self->fields } ) {

                    my $format = $self->format_fields->{$field}
                      or next;

                    $format{$field} = $format;
                }

            }

            return \%format
              if keys %format;
        }

        return;
    },
    init_arg => undef,
);

sub BUILD {

    my $self = shift;

    # if types is passed, set fields if it's not set.
    # convert types to hash if it's an array

    my $types;
    if ( defined( $types = $self->types ) ) {

        if ( 'HASH' eq ref $types ) {

            $self->_set_fields( [ keys %{$types} ] )
             unless $self->has_fields;
        }

        elsif ( 'ARRAY' eq ref $types ) {

            $self->_set_types( { @{$types} } );

            if ( ! $self->has_fields ) {

                my @fields;
                push @fields, $types->[ 2 * $_ ] for 0 .. ( @{$types} / 2 ) - 1;

                $self->_set_fields( \@fields );
            }
        }
        else {
            error( '::attribute::value', "internal error" );
        }

    }

    if ( $self->has_fields ) {

        if ( ref $self->fields ) {

            # in this specific case everything can be done before the first
            # record is read.  this is kind of overkill, but at least one
            # test depended upon being able to determine types prior
            # to sending the first record, so need to do this here rather
            # than in Default::setup
            if ( $self->_need_types && defined $self->default_type ) {
                $self->_set_types_from_default;
                $self->_set__need_types( 0 );
            }
        }

        # if fields eq 'all', clear out the attribute so that it will get
        # filled in when the first record is sent.
        else {
            $self->clear_fields;
        }
    }

    return;
}

sub _set_types_from_record {

    my ( $self, $data ) = @_;

    my $types = $self->has_types ? $self->types : {};

    for my $field ( grep !defined $types->{$_}, @{ $self->fields } ) {

        my $value = $data->{$field};
        my $def = Scalar::Util::looks_like_number( $value ) ? 'N' : 'S';

        $def = 'I'
          if $self->_use_integer
          && $def eq 'N'
          && POSIX::floor( $value ) == POSIX::ceil( $value );

        $types->{$field} = $def;
    }

    $self->_set_types( $types );
}

sub _set_types_from_default {

    my $self = shift;

    my $types = $self->has_types ? $self->types : {};

    $types->{$_} = $self->default_type
      for grep { !defined $types->{$_} } @{ $self->fields };

    $self->_set_types( $types );
}


1;

__END__

=begin pod_coverage

=head3 BUILD

=head3 default_type

=head3 fields

=head3 format

=head3 format_fields

=head3 format_types

=head3 rename_fields

=head3 types

=head3 has_types

=end pod_coverage
