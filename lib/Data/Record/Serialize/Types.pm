package Data::Record::Serialize::Types;

# ABSTRACT: Types for Data::Record::Serialize

use strict;
use warnings;

our $VERSION = '0.16';

use Type::Utils -all;
use Types::Standard -types;
use Type::Library -base,
  -declare => qw[ ArrayOfStr ];

use namespace::clean;

declare ArrayOfStr,
  as ArrayRef[ Str ];

coerce ArrayOfStr,
  from Str, q { [ $_ ] };


# COPYRIGHT

1;
