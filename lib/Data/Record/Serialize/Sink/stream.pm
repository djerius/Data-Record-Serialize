package Data::Record::Serialize::Sink::stream;

# ABSTRACT: output encoded data to a stream.


use Moo::Role;

our $VERSION = '0.08';

use IO::File;

use namespace::clean;

has output => (
    is      => 'ro',
);


has fh => (

    is => 'lazy',

    builder => sub {
        my $self = shift;

        return ( ! defined $self->output || $self->output eq '-' )
          ? \*STDOUT
          : ( IO::File->new( $self->output, 'w' )
              or croak( "unable to create @{[ $self->output ]}\n" ) );
    },

);

=for pod_coverage

=method print

=method say

=cut

sub print { shift->fh->print( @_ ) }
sub say   { shift->fh->say( @_ ) }



with 'Data::Record::Serialize::Role::Sink';

1;

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'stream', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> outputs encoded data to a
file handle.

It performs the L<B<Data::Record::Serialize::Role::Sink>> role.


=head1 INTERFACE

The following attributes may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:

=over

=item C<output>

The name of an output file or a reference to a scalar to which the records will be written.
C<output> may be set to C<-> to indicate output to the standard output stream.

=item C<fh>

A file handle.

=back

If neither is specified, output is written to the standard output
stream.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Data-Record-Serialize>.

