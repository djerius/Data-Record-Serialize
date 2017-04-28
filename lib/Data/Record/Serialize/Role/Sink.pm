package Data::Record::Serialize::Role::Sink;

# ABSTRACT: Sink Role

use Moo::Role;

use namespace::clean;

our $VERSION = '0.09';

requires 'print';
requires 'say';

1;

__END__

=head1 DESCRIPTION

If a role consumes this, it signals that it provides sink
capabilities.
