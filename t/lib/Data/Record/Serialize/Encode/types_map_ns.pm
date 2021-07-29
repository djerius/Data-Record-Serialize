package Data::Record::Serialize::Encode::types_map_ns;

use Moo::Role;

sub _map_types { { N => 'n', S => 's' } }
sub _use_integer { 0 }

with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
