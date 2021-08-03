package Data::Record::Serialize::Encode::yaml;

# ABSTRACT: encode a record as YAML

use Moo::Role;

our $VERSION = '0.24';

use YAML::Any qw[ Dump ];

use namespace::clean;

sub _needs_eol { 1 }

=for Pod::Coverage
 encode

=cut

sub encode { shift; Dump(@_) }

with 'Data::Record::Serialize::Role::Encode';

1;

# COPYRIGHT

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'yaml', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::yaml> encodes a record as YAML.

It performs the L<Data::Record::Serialize::Role::Encode> role.

=head1 INTERFACE

There are no additional attributes which may be passed to
L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
