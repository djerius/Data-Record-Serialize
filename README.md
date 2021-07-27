# NAME

Data::Record::Serialize - Flexible serialization of a record

# VERSION

version 0.24

# SYNOPSIS

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

# DESCRIPTION

**Data::Record::Serialize** encodes data records and sends them
somewhere. This module is primarily useful for output of sets of
uniformly structured data records.  It provides a uniform, thin,
interface to various serializers and output sinks.  Its _raison
d'etre_ is its ability to manipulate the records prior to encoding
and output.

- A record is a collection of fields, i.e. keys and _scalar_
values.
- All records are assumed to have the same structure.
- Fields may have simple types which may be determined automatically.
Some encoders use this information during encoding.
- Fields may be renamed upon output
- A subset of the fields may be selected for output.
- Fields may be formatted via `sprintf` prior to output

## Encoders

The available encoders and their respective documentation are:

- `dbi` - [Data::Record::Serialize::Encode::dbi](https://metacpan.org/pod/Data::Record::Serialize::Encode::dbi)

    Write to a database via **DBI**. This is a combined
    encoder and sink.

- `ddump` - [Data::Record::Serialize::Encode::ddump](https://metacpan.org/pod/Data::Record::Serialize::Encode::ddump)

    encode via [Data::Dumper](https://metacpan.org/pod/Data::Dumper)

- `json` - [Data::Record::Serialize::Encode::json](https://metacpan.org/pod/Data::Record::Serialize::Encode::json)
- `null` - send the data to the bit bucket.  This is a combined
encoder and sink.
- `rdb`  - [Data::Record::Serialize::Encode::rdb](https://metacpan.org/pod/Data::Record::Serialize::Encode::rdb)
- `yaml` - [Data::Record::Serialize::Encode::yaml](https://metacpan.org/pod/Data::Record::Serialize::Encode::yaml)

## Sinks

Sinks are where encoded data are sent.

The available sinks and their documentation are:

- `stream` - [Data::Record::Serialize::Sink::stream](https://metacpan.org/pod/Data::Record::Serialize::Sink::stream)
- `null` - send the encoded data to the bit bucket.

## Types

Some output encoders care about the type of a
field. **Data::Record::Serialize** recognizes three types:

- `N` - Numeric
- `I` - Integral
- `S` - String

Not all encoders support a separate integral type; in those cases
integer fields are treated as general numeric fields.

## Fields and their types

Which fields are output and how their types are determined depends
upon the `fields`, `types`, and `default_type` attributes.

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

## Errors

Most errors result in exception objects being thrown, typically in the
[Data::Record::Serialize::Error](https://metacpan.org/pod/Data::Record::Serialize::Error) hierarchy.

# ATTRIBUTES

## `encode`

_Required_. The encoding format.  Specific encoders may provide
additional, or require specific, attributes. See ["Encoders"](#encoders)
for more information.

## `sink`

Where the encoded data will be sent.  Specific sinks may provide
additional, or require specific attributes. See ["Sinks"](#sinks) for more
information.

The default output sink is `stream`, unless the encoder is also a
sink.

It is an error to specify a sink if the encoder already acts as one.

## `types`

A hash or array mapping input field names to types (`N`, `I`,
`S`).  If an array, the fields will be output in the specified
order, provided the encoder permits it (see below, however).  For example,

    # use order if possible
    types => [ c => 'N', a => 'N', b => 'N' ]

    # order doesn't matter
    types => { c => 'N', a => 'N', b => 'N' }

If `fields` is specified, then its order will override that specified
here.

To understand how this attribute works in concert with ["fields"](#fields) and
["default\_type"](#default_type), please see ["Fields and their types"](#fields-and-their-types).

## `default_type` _type_

If set, output fields whose types were not
specified via the `types` attribute will be assigned this type.
To understand how this attribute works in concert with ["fields"](#fields) and
["types"](#types), please see ["Fields and their types"](#fields-and-their-types).

## `fields`

Which fields to output.  It may be one of:

- An array containing the input names of the fields to be output. The
fields will be output in the specified order, provided the encoder
permits it.
- The string `all`, indicating that all input fields will be output.
- Unspecified or undefined.

To understand how this attribute works in concert with ["types"](#types) and
["default\_type"](#default_type), please see ["Fields and their types" in Data::Record::Serialize](https://metacpan.org/pod/Data::Record::Serialize#Fields-and-their-types).

## nullify

Specify which fields should be set to `undef` if they are
empty. Sinks should encode `undef` as the `null` value.  By default,
no fields are nullified.

**nullify** may be passed:

- an array

    It should be a list of input field names.  These names are verified
    against the input fields after the first record is read.

- a code ref

    The coderef is passed the object, and should return a list of input
    field names.  These names are verified against the input fields after
    the first record is read.

- a boolean

    If true, all field names are added to the list. When false, the list
    is emptied.

During verification, a
`Data::Record::Serialize::Error::Role::Base::fields` error is thrown
if non-existent fields are specified.  Verification is _not_
performed until the next record is sent (or the ["nullified"](#nullified) method
is called), so there is no immediate feedback.

## `format_fields`

A hash mapping the input field names to either a `sprintf` style
format or a coderef. This will be applied prior to encoding the
record, but only if the `format` attribute is also set.  Formats
specified here override those specified in `format_types`.

The coderef will be called with the value to format as its first
argument, and should return the formatted value.

## `format_types`

A hash mapping a field type (`N`, `I`, `S`) to a `sprintf` style
format or a coderef.  This will be applied prior to encoding the
record, but only if the `format` attribute is also set.  Formats
specified here may be overridden for specific fields using the
`format_fields` attribute.

The coderef will be called with the value to format as its first
argument, and should return the formatted value.

## `rename_fields`

A hash mapping input to output field names.  By default the input
field names are used unaltered.

## `format`

If true, format the output fields using the formats specified in the
`format_fields` and/or `format_types` options.  The default is false.

# METHODS

## **new**

    $s = Data::Record::Serialize->new( <attributes> );

Construct a new object. _attributes_ may either be a hashref or a
list of key-value pairs. See ["ATTRIBUTES"](#attributes) for more information.

## has\_types

returns true if ["types"](#types) has been set.

## has\_fields

returns true if ["fields"](#fields) has been set.

## **output\_fields**

    $array_ref = $s->output_fields;

The names of the transformed output fields, in order of output (not
obeyed by all encoders);

## has\_nullify

returns true if ["nullify"](#nullify) has been set.

## nullified

    $fields = $obj->nullified;

Returns a list of fields which are checked for empty values (see ["nullify"](#nullify)).

This will return `undef` if the list is not yet available (for example, if
fields names are determined from the first output record and none has been sent).

If the list of fields is available, calling **nullified** may result in
verification of the list of nullified fields against the list of
actual fields.  A disparity will result in an exception of class
`Data::Record::Serialize::Error::Role::Base::fields`.

## **numeric\_fields**

    $array_ref = $s->numeric_fields;

The input field names for those fields deemed to be numeric.

## **type\_index**

    $hash = $s->type_index;

A hash, keyed off of field type or category.  The values are
an array of field names.  _Don't edit this!_.

The hash keys are:

- `I`
- `N`
- `S`
- `numeric`

    `N` and `I`.

- `not_string`

    Everything but `S`.

## **output\_types**

    $hash_ref = $s->output_types;

The mapping between output field name and output field type.  If the
encoder has specified a type map, the output types are the result of
that mapping.

## **send**

    $s->send( \%record );

Encode and send the record to the associated sink.

**WARNING**: the passed hash is modified.  If you need the original
contents, pass in a copy.

# EXAMPLES

## Generate a JSON stream to the standard output stream

    $s = Data::Record::Serialize->new( encode => 'json' );

## Only output select fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
     );

## Format numeric fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format => 1,
      format_types => { N => '%0.4f' },
     );

## Override formats for specific fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
     );

## Rename fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
      rename_fields => { chip_id => 'CHIP' },
     );

## Specify field types

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
      rename_fields => { chip_id => 'CHIP' },
      types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
     );

## Switch to an SQLite database in `$dbname`

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

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

## Source

Source is available at

    https://gitlab.com/djerius/data-record-serialize

and may be cloned from

    https://gitlab.com/djerius/data-record-serialize.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [Data::Serializer](https://metacpan.org/pod/Data::Serializer)

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
