package Data::Record::Serialize;

# ABSTRACT: Flexible serialization of a record

use 5.010000;

use strict;
use warnings;

use warnings::register qw( Encode::dbi::queue );

use Data::Record::Serialize::Error -all;

our $VERSION = '0.24';

use Package::Variant
  importing => ['Moo'],
  subs      => [qw( with has )];

use namespace::clean;

=for Pod::Coverage make_variant

=cut

sub make_variant {
    my ( $class, $target, %attr ) = @_;

    error( 'attribute::value', "must specify <encode> attribute" )
      unless defined $attr{encode};

    with 'Data::Record::Serialize::Role::Base';

    my $encoder = 'Data::Record::Serialize::Encode::' . lc $attr{encode};

    with $encoder;

    if ( $target->does( 'Data::Record::Serialize::Role::Sink' ) ) {

    error( 'attribute::value', "encoder ($attr{encode}) is already a sink; don't specify a sink attribute\n"
        ) if defined $attr{sink};
    }

    else {
        # default sink
        my $sink = 'Data::Record::Serialize::Sink::'
          . ( $attr{sink} ? lc $attr{sink} : 'stream' );

        with $sink;
    }

    with 'Data::Record::Serialize::Role::Default';
}


=method B<new>

  $s = Data::Record::Serialize->new( %args );
  $s = Data::Record::Serialize->new( \%args );

Construct a new object. The following arguments are recognized:

=over

=item C<types> => I<hashref>|I<arrayref>

A hash or array mapping input field names to types (C<N>, C<I>,
C<S>, C<B> ).  If an array, the fields will be output in the specified
order, provided the encoder permits it (see below, however).  For example,

  # use order if possible
  types => [ c => 'N', a => 'N', b => 'N' ]

  # order doesn't matter
  types => { c => 'N', a => 'N', b => 'N' }

If C<fields> is specified, then its order will override that specified
here.

To understand how this attribute works in concert with L</fields> and
L</default_type>, please see L</Fields and their types>.

=item C<default_type> => C<S>|C<N>|C<I>|C<B>

The default input type for fields whose types were not specified via
the C<types>.

To understand how this attribute works in concert with L</fields> and
L</types>, please see L</Fields and their types>.

=item C<fields> => I<arrayref>|C<all>

The fields to output.  If it is the string C<all>,
all input fields will be output. If it is an arrayref, the
fields will be output in the specified order, provided the encoder
permits it.

To understand how this attribute works in concert with L</types> and
L</default_type>, please see L<Data::Record::Serialize/Fields and their types>.

=item C<encode> => I<encoder>

I<Required>. The encoding format.  Specific encoders may provide
additional, or require specific, attributes. See L</Encoders>
for more information.

=item C<sink> => I<sink>

Where the encoded data will be sent.  Specific sinks may provide
additional, or require specific attributes. See L</Sinks> for more
information.

The default output sink is C<stream>, unless the encoder is also a
sink.

It is an error to specify a sink if the encoder already acts as one.

=item C<nullify> => I<arrayref>|I<coderef>|Boolean

Fields that should be set to C<undef> if they are
empty. Sinks should encode C<undef> as the C<null> value.

B<nullify> may be passed:

=over

=item * an arrayref of input field names

=item * a coderef

The coderef is called as

  @input_field_names = $code->( $serializer_object )

=item * a Boolean

If true, all field names are added to the list. When false, the list
is emptied.

=back

Names are verified against the input fields after the first record is
sent. A C<Data::Record::Serialize::Error::Role::Base::fields> error is thrown
if non-existent fields are specified.

=item C<format_fields>

A hash mapping the input field names to either a C<sprintf> style
format or a coderef. This will be applied prior to encoding the
record, but only if the C<format> attribute is also set.  Formats
specified here override those specified in C<format_types>.

The coderef will be called with the value to format as its first
argument, and should return the formatted value.

=item C<format_types>

A hash mapping a field type (C<N>, C<I>, C<S>) to a C<sprintf> style
format or a coderef.  This will be applied prior to encoding the
record, but only if the C<format> attribute is also set.  Formats
specified here may be overridden for specific fields using the
C<format_fields> attribute.

The coderef will be called with the value to format as its first
argument, and should return the formatted value.

=item C<rename_fields>

A hash mapping input to output field names.  By default the input
field names are used unaltered.

=item C<format>

If true, format the output fields using the formats specified in the
C<format_fields> and/or C<format_types> options.  The default is false.


=back

=cut


sub new {
    my $class = shift;
    my $attr = 'HASH' eq ref $_[0] ? shift : {@_};

    my %class_attr = (
        encode => $attr->{encode},
        sink   => $attr->{sink},
    );

    $class = Package::Variant->build_variant_of( __PACKAGE__, %class_attr );

    return $class->new( $attr );
}

1;


# COPYRIGHT

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    # simple output to json
    $s = Data::Record::Serialize->new( encode => 'json', \%attr );
    $s->send( \%record );

    # cleanup record before sending
    $s = Data::Record::Serialize->new( encode => 'json',
        fields => [ qw( obsid chip_id phi theta ) ],
        format => 1,
        format_types => { N => '%0.4f' },
        format_fields => { obsid => '%05d' },
        rename_fields => { chip_id => 'CHIP' },
        types => { obsid => 'I', chip_id => 'S',
                   phi => 'N', theta => 'N' },
    );
    $s->send( \%record );


    # send to an SQLite database
    $s = Data::Record::Serialize->new(
        encode => 'dbi',
        dsn => [ 'SQLite', [ dbname => $dbname ] ],
        table => 'stuff',
        format => 1,
        fields => [ qw( obsid chip_id phi theta ) ],
        format_types => { N => '%0.4f' },
        format_fields => { obsid => '%05d' },
        rename_fields => { chip_id => 'CHIP' },
        types => { obsid => 'I', chip_id => 'S',
                   phi => 'N', theta => 'N' },
    );
    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize> encodes data records and sends them
somewhere. This module is primarily useful for output of sets of
uniformly structured data records.  It provides a uniform, thin,
interface to various serializers and output sinks.  Its I<raison
d'etre> is its ability to manipulate the records prior to encoding
and output.

=over

=item *

A record is a collection of fields, i.e. keys and I<scalar>
values.

=item *

All records are assumed to have the same structure.

=item *

Fields may have simple types.

=item *

Fields may be renamed upon output.

=item *

A subset of the fields may be selected for output.

=item *

Field values may be transformed prior to output.

=back

=head2 Types

Some output encoders care about the type of a
field. B<Data::Record::Serialize> recognizes thesea types:

=over

=item *

C<N> - Number (any number)

=item *

C<I> - Integer

Encoded as C<N> if not available.

=item *

C<S> - String

=item *

C<B> - Boolean

Encoded as C<I> if not available.

=back

Not all encoders support separate integer or Boolean types. Where not supported,
intgers are encoded as numbers and Booleans as integers.

Types may be specified for fields, or may be automatically determined
from the first record which is output.  It is not possible to
deterministically determine if a field is Boolean, so that must be
explicitly noted.  Boolean fields should be "truthy", e.g., when used
in a conditional, they evaluate to true or false.

=head2 Field transformation

Transformations can be applied to fields prior to output, and may be
specified for data types as well as for individual fields (the latter
take precedence).  Transformations are specified via the
L</formmat_fields> and L</format_types> parameters.  They
can either be a C<sprintf> compatible format string,

    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },

 or a code reference:

    format_types => { B => sub { Lingua::Boolean::Tiny::boolean( $_[0] ) } }

=head2 Encoders

The available encoders and their respective documentation are:

=over

=item *

C<dbi> - L<Data::Record::Serialize::Encode::dbi>

Write to a database via B<DBI>. This is a combined
encoder and sink.

=item *

C<ddump> - L<Data::Record::Serialize::Encode::ddump>

encode via L<Data::Dumper>

=item *

C<json> - L<Data::Record::Serialize::Encode::json>

=item *

C<null> - send the data to the bit bucket.  This is a combined
encoder and sink.

=item *

C<rdb>  - L<Data::Record::Serialize::Encode::rdb>

=item *

C<yaml> - L<Data::Record::Serialize::Encode::yaml>

=back

=head2 Sinks

Sinks are where encoded data are sent.

The available sinks and their documentation are:

=over

=item *

C<stream> - L<Data::Record::Serialize::Sink::stream>

=item *

C<null> - send the encoded data to the bit bucket.

=back


=head2 Fields and their types

Which fields are output and how their types are determined depends
upon the C<fields>, C<types>, and C<default_type> attributes.

In the following table:

 N   => not specified
 Y   => specified
 X   => doesn't matter
 all => the string 'all'

Automatic type determination is done by examining the first
record sent to the output stream.

  fields types default_type  Result
  ------ ----- ------------  ------

  N/all   N        N         All fields are output.
                             Types are automatically determined.

  N/all   N        Y         All fields are output.
                             Types are set to <default_type>.

    Y     N        N         Fields in <fields> are output.
                             Types are automatically determined.

    Y     Y        N         Fields in <fields> are output.
                             Fields in <types> get the specified type.
                             Types for other fields are automatically determined.

    Y     Y        Y         Fields in <fields> are output.
                             Fields in <types> get the specified type.
                             Types for other fields are set to <default_type>.

   all    Y        N         All fields are output.
                             Fields in <types> get the specified type.
                             Types for other fields are automatically determined.

   all    Y        Y         All fields are output.
                             Fields in <types> get the specified type.
                             Types for other fields are set to <default_type>.

    N     Y        X         Fields in <types> are output.
                             Types are specified by <types>.


=head2 Errors

Most errors result in exception objects being thrown, typically in the
L<Data::Record::Serialize::Error> hierarchy.

=head1 EXAMPLES

=head2 Generate a JSON stream to the standard output stream

  $s = Data::Record::Serialize->new( encode => 'json' );

=head2 Only output select fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
   );

=head2 Format numeric fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format => 1,
    format_types => { N => '%0.4f' },
   );

=head2 Override formats for specific fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
   );

=head2 Rename fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
    rename_fields => { chip_id => 'CHIP' },
   );

=head2 Specify field types

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
    rename_fields => { chip_id => 'CHIP' },
    types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
   );

=head2 Switch to an SQLite database in C<$dbname>

  $s = Data::Record::Serialize->new(
    encode => 'dbi',
    dsn => [ 'SQLite', [ dbname => $dbname ] ],
    table => 'stuff',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
    rename_fields => { chip_id => 'CHIP' },
    types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
   );


=head1 ATTRIBUTES

Object attributes are gathered from
L</Data::Serialize::Record::Role::Base>,
L</Data::Serialize::Record::Role::Default>,
and the L</Data::Serialize::Record::Encode>, and 
L</Data::Serialize::Record::Sink>,
modules.


=head1 SEE ALSO

L<Data::Serializer>

=for Pod::Coverage
  BUILD


=method B<send>

  $s->send( \%record );

Encode and send the record to the associated sink.

B<WARNING>: the passed hash is modified.  If you need the original
contents, pass in a copy.
