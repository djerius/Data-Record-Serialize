package Data::Record::Serialize::Encode::types_nis;

use Moo::Role;

sub _use_integer { 1 }

with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
