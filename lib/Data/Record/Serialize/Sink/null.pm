package Data::Record::Serialize::Sink::null;

# ABSTRACT: send output to nowhere.

use Moo::Role;

use namespace::clean;

our $VERSION = '0.12';

=begin pod_coverage

=head3 print

=head3 say

=head3 close

=end pod_coverage

=cut

sub print { }
sub say   { }
sub close { }


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
