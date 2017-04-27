package Data::Record::Serialize::Sink::null;

# ABSTRACT: send output to nowhere.

use Moo::Role;

use namespace::clean;

our $VERSION = '0.08';

=for pod_coverage

=method print

=method say

=cut

sub print {  }
sub say   {  }


with 'Data::Record::Serialize::Role::Sink';

1;

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'null', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> sends data to the bitbucket.

It performs the L<B<Data::Record::Serialize::Role::Sink>> role.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Data-Record-Serialize>.

