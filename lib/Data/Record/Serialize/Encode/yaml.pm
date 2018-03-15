package Data::Record::Serialize::Encode::yaml;

# ABSTRACT: encode a record as YAML

use Moo::Role;

our $VERSION = '0.14';

use YAML::Any qw[ Dump ];

use namespace::clean;

has '+_need_types' => ( is => 'rwp', default => 0 );
has '+_needs_eol' => ( is => 'rwp', default => 1 );

=begin pod_coverage

=head3 encode

=end pod_coverage

=cut


sub encode { shift; goto \&Dump; }

with 'Data::Record::Serialize::Role::Encode';

1;

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'yaml', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::yaml> encodes a record as YAML.

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
