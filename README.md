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
- Fields may have simple types.
- Fields may be renamed upon output.
- A subset of the fields may be selected for output.
- Field values may be transformed prior to output.

## Types

Some output encoders care about the type of a
field. **Data::Record::Serialize** recognizes thesea types:

- `N` - Number (any number)
- `I` - Integer

    Encoded as `N` if not available.

- `S` - String
- `B` - Boolean

    Encoded as `I` if not available.

Not all encoders support separate integer or Boolean types. Where not supported,
intgers are encoded as numbers and Booleans as integers.

Types may be specified for fields, or may be automatically determined
from the first record which is output.  It is not possible to
deterministically determine if a field is Boolean, so that must be
explicitly noted.  Boolean fields should be "truthy", e.g., when used
in a conditional, they evaluate to true or false.

## Field transformation

Transformations can be applied to fields prior to output, and may be
specified for data types as well as for individual fields (the latter
take precedence).  Transformations are specified via the
["formmat\_fields"](#formmat_fields) and ["format\_types"](#format_types) parameters.  They
can either be a `sprintf` compatible format string,

       format_types => { N => '%0.4f' },
       format_fields => { obsid => '%05d' },

    or a code reference:

       format_types => { B => sub { Lingua::Boolean::Tiny::boolean( $_[0] ) } }

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

## Fields and their types

Which fields are output and how their types are determined depends
upon the `fields`, `types`, and `default_type` attributes.

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

## Errors

Most errors result in exception objects being thrown, typically in the
[Data::Record::Serialize::Error](https://metacpan.org/pod/Data::Record::Serialize::Error) hierarchy.

# METHODS

## **new**

    $s = Data::Record::Serialize->new( %args );
    $s = Data::Record::Serialize->new( \%args );

Construct a new object. The following arguments are recognized:

- `types` => _hashref_|_arrayref_

    A hash or array mapping input field names to types (`N`, `I`,
    `S`, `B` ).  If an array, the fields will be output in the specified
    order, provided the encoder permits it (see below, however).  For example,

        # use order if possible
        types => [ c => 'N', a => 'N', b => 'N' ]

        # order doesn't matter
        types => { c => 'N', a => 'N', b => 'N' }

    If `fields` is specified, then its order will override that specified
    here.

    To understand how this attribute works in concert with ["fields"](#fields) and
    ["default\_type"](#default_type), please see ["Fields and their types"](#fields-and-their-types).

- `default_type` => `S`|`N`|`I`|`B`

    The default input type for fields whose types were not specified via
    the `types`.

    To understand how this attribute works in concert with ["fields"](#fields) and
    ["types"](#types), please see ["Fields and their types"](#fields-and-their-types).

- `fields` => _arrayref_|`all`

    The fields to output.  If it is the string `all`,
    all input fields will be output. If it is an arrayref, the
    fields will be output in the specified order, provided the encoder
    permits it.

    To understand how this attribute works in concert with ["types"](#types) and
    ["default\_type"](#default_type), please see ["Fields and their types" in Data::Record::Serialize](https://metacpan.org/pod/Data::Record::Serialize#Fields-and-their-types).

- `encode` => _encoder_

    _Required_. The encoding format.  Specific encoders may provide
    additional, or require specific, attributes. See ["Encoders"](#encoders)
    for more information.

- `sink` => _sink_

    Where the encoded data will be sent.  Specific sinks may provide
    additional, or require specific attributes. See ["Sinks"](#sinks) for more
    information.

    The default output sink is `stream`, unless the encoder is also a
    sink.

    It is an error to specify a sink if the encoder already acts as one.

- `nullify` => _arrayref_|_coderef_|Boolean

    Fields that should be set to `undef` if they are
    empty. Sinks should encode `undef` as the `null` value.

    **nullify** may be passed:

    - an arrayref of input field names
    - a coderef

        The coderef is called as

            @input_field_names = $code->( $serializer_object )

    - a Boolean

        If true, all field names are added to the list. When false, the list
        is emptied.

    Names are verified against the input fields after the first record is
    sent. A `Data::Record::Serialize::Error::Role::Base::fields` error is thrown
    if non-existent fields are specified.

- `format_fields`

    A hash mapping the input field names to either a `sprintf` style
    format or a coderef. This will be applied prior to encoding the
    record, but only if the `format` attribute is also set.  Formats
    specified here override those specified in `format_types`.

    The coderef will be called with the value to format as its first
    argument, and should return the formatted value.

- `format_types`

    A hash mapping a field type (`N`, `I`, `S`) to a `sprintf` style
    format or a coderef.  This will be applied prior to encoding the
    record, but only if the `format` attribute is also set.  Formats
    specified here may be overridden for specific fields using the
    `format_fields` attribute.

    The coderef will be called with the value to format as its first
    argument, and should return the formatted value.

- `rename_fields`

    A hash mapping input to output field names.  By default the input
    field names are used unaltered.

- `format`

    If true, format the output fields using the formats specified in the
    `format_fields` and/or `format_types` options.  The default is false.

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

# ATTRIBUTES

Object attributes are gathered from
["Data::Serialize::Record::Role::Base"](#data-serialize-record-role-base),
["Data::Serialize::Record::Role::Default"](#data-serialize-record-role-default),
and the ["Data::Serialize::Record::Encode"](#data-serialize-record-encode), and 
["Data::Serialize::Record::Sink"](#data-serialize-record-sink),
modules.

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
