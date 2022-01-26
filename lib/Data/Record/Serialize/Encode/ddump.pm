package Data::Record::Serialize::Encode::ddump;

# ABSTRACT:  encoded a record using Data::Dumper

use Moo::Role;

our $VERSION = '0.34';

use Data::Dumper;

use namespace::clean;

sub _needs_eol { 1 }

=for Pod::Coverage
  encode

=cut

sub encode {
    shift;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Trailingcomma = 1;
    Data::Dumper::Dumper( @_ ) . ",\n";
}

with 'Data::Record::Serialize::Role::Encode';

1;

# COPYRIGHT

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'ddump', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::ddump> encodes a record using
L<Data::Dumper>.  The resultant encoding may be decoded via

  @data = eval $buf;

It performs the L<Data::Record::Serialize::Role::Encode> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<< Data::Record::Serialize::new|Data::Record::Serialize/new >>.

