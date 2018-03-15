package Data::Record::Serialize::Encode::null;

# ABSTRACT: infinite bitbucket

use Moo::Role;

our $VERSION = '0.14';

use namespace::clean;

has '+_need_types' => ( is => 'rwp', default => 0 );

=begin pod_coverage

=head3 encode

=head3 send

=head3 print

=head3 say

=head3 close

=end pod_coverage

=cut

sub encode { }
sub send {  }
sub print { }
sub say { }
sub close { }

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
