package Data::Record::Serialize::Sink::stream;

# ABSTRACT: output encoded data to a stream.


use Moo::Role;

use Data::Record::Serialize::Error { errors => [ '::create' ] }, -all;

our $VERSION = '0.30';

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
              or error( '::create', "unable to create @{[ $self->output ]}" ) );
    },
   clearer => 1,
   predicate => 1,
);

=for Pod::Coverage
 print
 say
 close
 has_fh
 clear_fh
=cut

sub print { shift->fh->print( @_ ) }
sub say   { shift->fh->say( @_ ) }

sub close {
    my ( $self, $in_global_destruction ) = @_;

    # don't bother closing the FH; it'll be done on its own.
    return if $in_global_destruction;

    # fh is lazy, so the object may close without every using it, so
    # don't inadvertently create it.
    $self->fh->close if $self->has_fh;
    $self->clear_fh;
}

with 'Data::Record::Serialize::Role::Sink';

1;

# COPYRIGHT

__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( sink => 'stream', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Sink::stream> outputs encoded data to a
file handle.

It performs the L<Data::Record::Serialize::Role::Sink> role.


=head1 INTERFACE

The following attributes may be passed to
L<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:

=over

=item C<output>

The name of an output file or a reference to a scalar to which the records will be written.
C<output> may be set to C<-> to indicate output to the standard output stream.

=item C<fh>

A file handle.

=back

If neither is specified, output is written to the standard output
stream.
