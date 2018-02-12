package Data::Record::Serialize::Encode::ddump;

# ABSTRACT:  encoded a record using Data::Dumper

use Moo::Role;

our $VERSION = '0.13';

use Data::Dumper;

use namespace::clean;

before BUILD => sub {

    my $self = shift;

    $self->_set__need_types( 0 );
    $self->_set__needs_eol( 1 );

};

=begin pod_coverage

=head3 encode

=end pod_coverage

=cut


sub encode {
    shift;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Trailingcomma = 1;
    Data::Dumper::Dumper( @_ ) . ",\n";
}

with 'Data::Record::Serialize::Role::Encode';


1;

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'ddump', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::ddump> encodes a record using
L<B<Data::Dumper>>.  The resultant encoding may be decoded via

  @data = eval $buf;

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>.

