package Data::Record::Serialize::Sink::array;

# ABSTRACT: append encoded data to an array.


use Moo::Role;

use Data::Record::Serialize::Error { errors => [ '::create' ] }, -all;

our $VERSION = '0.30';

use IO::File;

use namespace::clean;

=attr output

  $array = $s->output;

The array into which the encoded record is stored.  The last record sent is at

   $s->output->[-1]

=cut

has output => (
               is      => 'ro',
               clearer => 1,
               default => sub { [] },
);

=for Pod::Coverage
 print
 say
 close

=cut

sub print { push @{shift->{output}}, @_ }
*say = \&print;
sub close {}

with 'Data::Record::Serialize::Role::Sink';

1;

# COPYRIGHT

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'array', ?(output => \@output), ... );

    $s->send( \%record );

    # last encoded record is here
    $encoded = $s->output->[-1];


=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::sink> appends encoded data to an array.

It performs the L<Data::Record::Serialize::Role::Sink> role.


=head1 CONSTRUCTOR OPTIONS

=over

=item output => I<arrayref>

Optional. Where to write the data. An arrayref is provided if not specified.

=back
