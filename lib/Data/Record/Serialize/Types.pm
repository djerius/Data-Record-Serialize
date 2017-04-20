package Data::Record::Serialize::Types;

use Carp;

use Scalar::Util qw[ blessed ];

use Type::Library
  -base,
  -declare => qw(
  DataType
  MetadataDict
);

use Type::Utils -all;

BEGIN {
    extends 'Types::Standard';
}

our @EXPORT_OK = qw[ slurpy ];


declare DataType,
as Enum[qw( N I S )];

1;
