package Data::Record::Serialize::Encode::yaml;

# ABSTRACT: encode a record as YAML

use Moo::Role;

our $VERSION = '0.08';

use YAML::Any qw[ Dump ];

use namespace::clean;

before BUILD => sub {

    my $self = shift;

    $self->_set__need_types( 0 );
    $self->_set__needs_eol( 1 );
};

=for pod_coverage

=method encode

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

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Data-Record-Serialize>.

