package Data::Record::Serialize::Encode::both;

use Moo::Role;

sub print {}
sub say {}
sub encode {}

with 'Data::Record::Serialize::Role::Encode';
with 'Data::Record::Serialize::Role::Sink';

1;
