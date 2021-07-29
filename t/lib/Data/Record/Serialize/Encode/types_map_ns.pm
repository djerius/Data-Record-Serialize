package Data::Record::Serialize::Encode::types_map_ns;

use Moo::Role;

sub _map_types { { N => 'n', S => 's' } }

before BUILD => sub {
    $_[0]->_set__use_integer( 0 );
};


with 'Data::Record::Serialize::Encode::null';
with 'Data::Record::Serialize::Sink::null';

1;
