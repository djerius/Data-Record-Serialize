package Data::Record::Serialize::Encode::types_map;

use Moo::Role;

sub _map_types { { N => 'n', I => 'i', S => 's' } }
sub _use_integer { 1 }

with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
