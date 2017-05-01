package Data::Record::Serialize::Encode::json;

# ABSTRACT: encoded a record as JSON

use Moo::Role;

our $VERSION = '0.11';

use JSON::MaybeXS qw[ encode_json ];

use namespace::clean;

before BUILD => sub {

    my $self = shift;

    $self->_set__numify( 1 );
    $self->_set__needs_eol( 1 );
};

=begin pod_coverage

=head3 encode

=end pod_coverage

=cut

sub encode { shift; goto \&encode_json }

with 'Data::Record::Serialize::Role::Encode';

1;


__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'json', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::json> encodes a record as JSON.

If a field's type is C<N> or C<I>, it will be properly encoded by JSON
as a number.

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.
