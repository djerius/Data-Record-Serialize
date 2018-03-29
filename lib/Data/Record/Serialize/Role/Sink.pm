package Data::Record::Serialize::Role::Sink;

# ABSTRACT: Sink Role

use Moo::Role;

use namespace::clean;

our $VERSION = '0.15';

requires 'print';
requires 'say';

=method B<close>

  $s->close;

Flush any data written to the sink and close it.  While this will be
performed automatically when the object is destroyed, if the object is
not destroyed prior to global destruction at the end of the program,
it is quite possible that it will not be possible to perform this
cleanly.  In other words, make sure that sinks are closed prior to
global destruction.


=cut

requires 'close';

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

If a role consumes this, it signals that it provides sink
capabilities.
