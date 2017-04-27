package Data::Record::Serialize::Encode::null;

# ABSTRACT: infinite bitbucket

use Moo::Role;

our $VERSION = '0.08';

use namespace::clean;


=for pod_coverage

=method send

=cut

sub send {  }

with 'Data::Record::Serialize::Role::Encode';
with 'Data::Record::Serialize::Role::Sink';

1;

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'null', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::null> is both an encoder and a sink.
All records sent using it will disappear.

It performs both the L<B<Data::Record::Serialize::Role::Encode>> and
L<B<Data::Record::Serialize::Role::Sink>> roles.

=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize::new>|Data::Record::Serialize/new>.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Data-Record-Serialize>.

