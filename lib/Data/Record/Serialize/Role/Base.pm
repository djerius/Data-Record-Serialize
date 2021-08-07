package Data::Record::Serialize::Role::Base;

# ABSTRACT: Base Role for Data::Record::Serialize

use Moo::Role;

our $VERSION = '0.28';

use Data::Record::Serialize::Error { errors => [ 'fields', 'types' ] }, -all;

use Data::Record::Serialize::Util -all;

use Types::Standard
  qw[ ArrayRef CodeRef CycleTuple HashRef Enum Str Bool is_HashRef Maybe ];
use Data::Record::Serialize::Types qw( SerializeType );

use Ref::Util qw( is_coderef is_arrayref );
use List::Util 1.33 qw( any );

use POSIX ();

use namespace::clean;

=attr C<types>

If no types are available, returns C<undef>; see also L</has_types>.

Otherwise, returns a hashref whose keys are the input field names and
whose values are the types (C<N>, C<I>, C<S>, C<B>). If types are
deduced from the data, this mapping is finalized (and thus accurate)
only after the first record has been sent.

=method has_types

returns true if L</types> has been set.

=cut

has types => (
    is  => 'rwp',
    isa => ( HashRef [ SerializeType ] | CycleTuple [ Str, SerializeType ] ),   # need parens for perl <= 5.12.5
    predicate => 1,
    trigger   => sub {
        $_[0]->clear_type_index;
        $_[0]->clear_output_types;
    },
);

=attr C<default_type> I<type>

The value passed to the constructor (if any).

=cut

=method has_default_type

returns true if L</default_type> has been set.

=cut

has default_type => (
    is  => 'ro',
    isa => SerializeType,
    predicate => 1
);

=attr C<fields>

The names of the input fields that will be output.

=method has_fields

returns true if L</fields> has been set.

=cut

has fields => (
    is      => 'rwp',
    isa     => ( ArrayRef [Str] | Enum ['all'] ),  # need parens for perl <= 5.12.5
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
        @fieldh{ @{ $self->fields } } = ();
        return \%fieldh;
    },
);


=method B<output_fields>

  $array_ref = $s->output_fields;

The names of the output fields, in order of requested output.  This takes into account
fields which have been renamed.

=cut

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

# something for other roles to wrap.
sub _trigger_output_fields { }

has _run_setup => (
    is        => 'rwp',
    isa       => Bool,
    init_args => undef,
    default   => 1,
);


# have we initialized types? can't simply use $self->has_types, as
# the caller may have provided some.
has _have_initialized_types => (
    is       => 'rwp',
    init_arg => undef,
    isa      => Bool,
    default  => 0,
);

has _boolify => (
    is       => 'lazy',
    isa      => Bool,
    init_arg => undef,
    builder  => sub { $_[0]->_can_bool || $_[0]->_convert_boolean_to_int },
);

has _convert_boolean_to_int => (
    is      => 'rwp',
    default => 0,
);

has _can_bool => (
    is       => 'lazy',
    isa      => Bool,
    init_arg => undef,
    builder  => sub { !! $_[0]->can( 'to_bool' ) },
);


=begin internals

=sub _build_field_list_with_type

  $list = $s->_build_field_list_with_type( $list_spec, $type, $error_label );

Given a specification for a list (see the nullify, stringify, and
numify attributes) and the field type (e.g. STRING, NUMERIC, BOOLEAN,
ANY ) if the specification is boolean, return a list.

=end internals


=cut

sub _build_field_list_with_type {
    my ( $self, $list_spec, $type, $error_label ) = @_;

    my $list = do {
        if ( is_coderef( $list_spec ) ) {
            ( ArrayRef [Str] )->assert_return( $list_spec->( $self ) );
        }
        elsif ( is_arrayref( $list_spec ) ) {
            [@$list_spec];
        }
        else {
            [ $list_spec ? @{ $self->type_index->[ $type ] } : () ];
        }
    };
    my $fieldh    = $self->_fieldh;
    my @not_field = grep { !exists $fieldh->{$_} } @{$list};
    error( 'fields', "unknown $error_label fields: " . join( ', ', @not_field ) )
      if @not_field;

    return $list;
}

=attr nullify

The value passed to the constructor (if any).

=method has_nullify

returns true if L</nullify> has been set.

=attr numify

   $bool = $s->numify;

The value passed to the constructor (if any).
See the discussion for the L<< numify|Data::Record::Serialize/numify >> constructor option.

=method has_numify

returns true if L</numify> has been set.

=attr stringify

   $bool = $s->stringify;

The value passed to the constructor (if any).
See the discussion for the L<< stringify|Data::Record::Serialize/stringify >> constructor option.

=method has_stringify

returns true if L</stringify> has been set.


=cut


has [ 'nullify', 'numify', 'stringify' ] => (
    is        => 'rw',
    isa       => ( ArrayRef [Str] | CodeRef | Bool ),  # need parens for perl <= 5.12.5
    predicate => 1,
    trigger   => 1,
);

sub _trigger_nullify   { $_[0]->_clear_nullified }
sub _trigger_numify    { $_[0]->_clear_numified }
sub _trigger_stringify { $_[0]->_clear_stringified }

=method nullified

  $fields = $obj->nullified;

Returns a list of fields which are checked for empty values (see L</nullify>).

This will return C<undef> if the list is not yet available (for example, if
fields names are determined from the first output record and none has been sent).

If the list of fields is available, calling B<nullified> may result in
verification of the list of nullified fields against the list of
actual fields.  A disparity will result in an exception of class
C<Data::Record::Serialize::Error::Role::Base::fields>.

=cut

sub nullified {
    my $self = shift;
    return [ $self->has_fields ? @{$self->_nullified} : () ];
}


=method numified

  $fields = $obj->numified;

Returns a list of fields which are converted to numbers.

This will return C<undef> if the list is not yet available (for example, if
fields names are determined from the first output record and none has been sent).

If the list of fields is available, calling B<numified> may result in
verification of the list of numified fields against the list of
actual fields.  A disparity will result in an exception of class
C<Data::Record::Serialize::Error::Role::Base::fields>.

=cut

sub numified {
    my $self = shift;
    return [ $self->has_fields ? @{$self->_numified} : () ];
}

=method stringified

  $fields = $obj->stringified;

Returns a list of fields which are converted to strings.

This will return C<undef> if the list is not yet available (for example, if
fields names are determined from the first output record and none has been sent).

If the list of fields is available, calling B<stringified> may result in
verification of the list of stringified fields against the list of
actual fields.  A disparity will result in an exception of class
C<Data::Record::Serialize::Error::Role::Base::fields>.

=cut

sub stringified {
    my $self = shift;
    return [ $self->has_fields ? @{$self->_stringified} : () ];
}


has [ '_nullified', '_numified', '_stringified' ] => (
    is        => 'lazy',
    isa       => ArrayRef [Str],
    clearer   => 1,
    predicate => 1,
    init_arg  => undef,
    builder   => 1,
);

sub _build__nullified {
    my $self = shift;
    return $self->has_nullify
      ? $self->_build_field_list_with_type( $self->nullify, ANY, 'nullify' )
      : [];
}

sub _build__numified {
    my $self = shift;
    return $self->has_numify
      ? $self->_build_field_list_with_type( $self->numify, NUMBER, 'numify' )
      : [];
}

sub _build__stringified {
    my $self = shift;
    return $self->has_stringify
      ? $self->_build_field_list_with_type( $self->stringify, STRING, 'stringify' )
      : [];
}


=method B<string_fields>

  $array_ref = $s->string_fields;

The input field names for those fields deemed to be strings

=cut

sub string_fields { $_[0]->type_index->[STRING] }


=method B<numeric_fields>

  $array_ref = $s->numeric_fields;

The input field names for those fields deemed to be numeric (either N or I).

=cut

sub numeric_fields { $_[0]->type_index->[NUMBER] }


=method B<boolean_fields>

  $array_ref = $s->boolean_fields;

The input field names for those fields deemed to be boolean.

=cut

sub boolean_fields { $_[0]->type_index->[ BOOLEAN ] }


=method B<type_index>

  $arrayref = $s->type_index;

An array, with indices representing field type or category.  The values are
an array of field names. This is finalized (and thus accurate) only after the first record is written.

I<Don't edit this!>.

The indices are available via L<Data::Record::Serialize::Util> and are:

=over

=item INTEGER

=item FLOAT

=item NUMBER

C<FLOAT> and C<INTEGER>

=item STRING

=item NOT_STRING

everything that's not C<STRING>

=item BOOLEAN

=back

=cut

has type_index => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        error( 'types', "no types for fields are available" )
          unless $self->has_types;
        index_types( $self->types );
    },
);

=method B<output_types>

  $hash_ref = $s->output_types;

The fully resolved mapping between output field name and output field type.  If the
encoder has specified a type map, the output types are the result of
that mapping.  This is only valid after the first record has been sent.

=cut

has output_types => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    trigger  => 1,
);

sub _build_output_types {
    my $self = shift;
    my %types;

    return
      unless $self->has_types;

    my @int_fields = grep { defined $self->types->{$_} } @{ $self->fields };
    @types{@int_fields} = @{ $self->types }{@int_fields};

    unless ( $self->_encoder_has_type(BOOLEAN) ) {
        $types{$_} = T_INTEGER for @{ $self->boolean_fields };
        $self->_set__convert_boolean_to_int(1);
    }

    unless ( $self->_encoder_has_type(INTEGER) ) {
        $types{$_} = T_NUMBER for @{ $self->numeric_fields };
    }

    if ( my $map_types = $self->_map_types ) {
        for my $field ( keys %types ) {
            my $type = $types{$field};
            next unless  exists $map_types->{$type};
            $types{$field} = $map_types->{ $type }
        }
    }

    for my $key ( keys %types ) {
        my $rename = $self->rename_fields->{$key}
          or next;

        $types{$rename} = delete $types{$key};
    }

    \%types;
}

# something for other roles to wrap.
sub _trigger_output_types { }


sub _encoder_has_type {
    my ( $self, $type ) = @_;
    any { is_type($_, $type ) } keys %{ $self->_map_types // {} };
}


=attr C<format_fields>

The value passed to the constructor (if any).

=cut

has format_fields => (
    is  => 'ro',
    isa => HashRef [Str | CodeRef],
);

=attr C<format_types>

The value passed to the constructor (if any).

=cut

has format_types => (
    is        => 'ro',
    isa       => HashRef [ Str | CodeRef ],
);


=attr C<rename_fields>

The value passed to the constructor (if any).

=cut

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


=attr C<format>

If true, format the output fields using the formats specified in the
C<format_fields> and/or C<format_types> options.  The default is false.

=cut

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

=for Pod::Coverage
  BUILD

=cut

sub BUILD {
    my $self = shift;

    # if types is passed, set fields if it's not set.
    # convert types to hash if it's an array
    if ( $self->has_types ) {
        my $types = $self->types;

        if ( 'HASH' eq ref $types ) {
            $self->_set_fields( [ keys %{$types} ] )
             unless $self->has_fields;
        }
        elsif ( 'ARRAY' eq ref $types ) {
            $self->_set_types( { @{$types} } );

            if ( ! $self->has_fields ) {
                my @fields;
                # pull off "keys"
                push @fields, ( shift @$types, shift @$types )[0] while @$types;
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
            $self->_set_types_from_default
              if $self->has_default_type;
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

    return if $self->_have_initialized_types;

    my $types = $self->has_types ? $self->types : {};

    for my $field ( grep !defined $types->{$_}, @{ $self->fields } ) {
        my $value = $data->{$field};
        my $def = Scalar::Util::looks_like_number( $value ) ? T_NUMBER : T_STRING;

        $def = T_INTEGER
          if $def eq T_NUMBER
          && POSIX::floor( $value ) == POSIX::ceil( $value );

        $types->{$field} = $def;
    }

    $self->_set_types( $types );
    $self->_set__have_initialized_types( 1 );
}

sub _set_types_from_default {
    my $self = shift;

    return if $self->_have_initialized_types;

    my $types = $self->has_types ? $self->types : {};

    $types->{$_} = $self->default_type
      for grep { !defined $types->{$_} } @{ $self->fields };

    $self->_set_types( $types );
    $self->_set__have_initialized_types( 1 );
}


1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

C<Data::Record::Serialize::Role::Base> is the base role for
L<Data::Record::Serialize>.  It serves the place of a base class, except
as a role there is no overhead during method lookup

