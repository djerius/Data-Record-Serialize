package Data::Record::Serialize;

# ABSTRACT: Flexible serialization of a record

use 5.010000;

use strict;
use warnings;

use Data::Record::Serialize::Error -all;

our $VERSION = '0.14';

use Package::Variant
  importing => ['Moo'],
  subs      => [qw( with has )];

use namespace::clean;

=begin pod_coverage

=head3 make_variant

=end pod_coverage

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

Fields may have simple types which may be determined automatically.
Some encoders use this information during encoding.

=item *

Fields may be renamed upon output

=item *

A subset of the fields may be selected for output.

=item *

Fields may be formatted via C<sprintf> prior to output

=back

=head2 Encoders

The available encoders and their respective documentation are:

=over

=item *

C<dbi> - L<B<Data::Record::Serialize::Encode::dbi>>

Write to a database via B<DBI>. This is a combined
encoder and sink.

=item *

C<ddump> - L<B<Data::Record::Serialize::Encode::ddump>>

encode via L<B<Data::Dumper>>

=item *

C<json> - L<B<Data::Record::Serialize::Encode::json>>

=item *

C<null> - send the data to the bit bucket.  This is a combined
encoder and sink.

=item *

C<rdb>  - L<B<Data::Record::Serialize::Encode::rdb>>

=item *

C<yaml> - L<B<Data::Record::Serialize::Encode::yaml>>

=back


=head2 Sinks

Sinks are where encoded data are sent.

The available sinks and their documentation are:

=over

=item *

C<stream> - L<B<Data::Record::Serialize::Sink::stream>>

=item *

C<null> - send the encoded data to the bit bucket.

=back


=head2 Types

Some output encoders care about the type of a
field. B<Data::Record::Serialize> recognizes three types:

=over

=item *

C<N> - Numeric

=item *

C<I> - Integral

=item *

C<S> - String

=back

Not all encoders support a separate integral type; in those cases
integer fields are treated as general numeric fields.

=head2 Fields and their types

Which fields are output and how their types are determined depends
upon the C<fields>, C<types>, and C<default_type> attributes.

In the following table:

 N   => not specified
 Y   => specified
 X   => doesn't matter
 all => the string 'all'

Automatic type determination is done by examining the first
record send to the output stream.

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


=head1 INTERFACE

=head2 Errors

Most errors result in exception objects being thrown, typically in the
L<Data::Record::Serialize::Error> hierarchy.

=head2 B<new>

  $s = Data::Record::Serialize->new( <attributes> );

Construct a new object. I<attributes> may either be a hashref or a
list of key-value pairs.

The available attributes are:

=over

=item C<encode>

I<Required>. The encoding format.  Specific encoders may provide
additional, or require specific, attributes. See L</Encoders>
for more information.

=item C<sink>

Where the encoded data will be sent.  Specific sinks may provide
additional, or require specific attributes. See L</Sinks> for more
information.

The default output sink is C<stream>, unless the encoder is also a
sink.

It is an error to specify a sink if the encoder already acts as one.

=item C<default_type>=I<type>

If set, output fields whose types were not
specified via the C<types> attribute will be assigned this type.
To understand how this attribute works in concert with L</fields> and
L</types>, please see L</Fields and their types>.

=item C<types>

A hash or array mapping input field names to types (C<N>, C<I>,
C<S>).  If an array, the fields will be output in the specified
order, provided the encoder permits it (see below, however).  For example,

  # use order if possible
  types => [ c => 'N', a => 'N', b => 'N' ]

  # order doesn't matter
  types => { c => 'N', a => 'N', b => 'N' }

If C<fields> is specified, then its order will override that specified
here.

To understand how this attribute works in concert with L</fields> and
L</default_type>, please see L</Fields and their types>.


=item C<fields>

Which fields to output.  It may be one of:

=over

=item * 

An array containing the input names of the fields to be output. The
fields will be output in the specified order, provided the encoder
permits it.

=item *

The string C<all>, indicating that all input fields will be output.

=item *

Unspecified or undefined.

=back

To understand how this attribute works in concert with L</types> and
L</default_type>, please see L</Fields and their types>.


=item C<rename_fields>

A hash mapping input to output field names.  By default the input
field names are used unaltered.

=item C<format_fields>

A hash mapping the input field names to a C<sprintf> style
format. This will be applied prior to encoding the record, but only if
the C<format> attribute is also set.  Formats specified here override
those specified in C<format_types>.

=item C<format_types>

A hash mapping a field type (C<N>, C<I>, C<S>) to a C<sprintf> style
format.  This will be applied prior to encoding the record, but only
if the C<format> attribute is also set.  Formats specified here may be
overridden for specific fields using the C<format_fields> attribute.

=item C<format>

If true, format the output fields using the formats specified in the
C<format_fields> and/or C<format_types> options.  The default is false.

=back

=head2 B<send>

  $s->send( \%record );

Encode and send the record to the associated sink.

B<WARNING>: the passed hash is modified.  If you need the original
contents, pass in a copy.


=head2 B<close>

  $s->close;

Flush any data written to the sink and close it.  While this will be
performed automatically when the object is destroyed, if the object is
not destroyed prior to global destruction at the end of the program,
it is quite possible that it will not be possible to perform this
cleanly.  In other words, make sure that sinks are closed prior to
global destruction.

=head2 B<output_fields>

  $array_ref = $s->output_fields;

The names of the transformed output fields, in order of output (not
obeyed by all encoders);

=head2 B<output_types>

  $hash_ref = $s->output_types;

The mapping between output field name and output field type.  If the
encoder has specified a type map, the output types are the result of
that mapping.

=head2 B<numeric_fields>

  $array_ref = $s->numeric_fields;

The input field names for those fields deemed to be numeric.

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



=head1 SEE ALSO

Other modules:

L<B<Data::Serializer>>




