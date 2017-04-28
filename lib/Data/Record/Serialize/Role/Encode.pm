package Data::Record::Serialize::Role::Encode;

# ABSTRACT: Encode Role

use Moo::Role;

use namespace::clean;

our $VERSION = '0.10';

requires 'encode';

1;

__END__

=head1 DESCRIPTION

If a role consumes this, it signals that it provides encoding
capabilities.
