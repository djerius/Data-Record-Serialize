package Data::Record::Serialize::Encode::types_nis;

use Moo::Role;

sub _map_types { { I => 'I' } }

with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
