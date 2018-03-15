package Data::Record::Serialize::Encode::rdb;

# ABSTRACT: encoded a record as /rdb

use Moo::Role;

our $VERSION = '0.14';

has '+_need_types' => (
    is      => 'rwp',
    default => 1,
);
has '+_use_integer' => (
    is      => 'rwp',
    default => 0,
);
has '+_map_types' => (
    is      => 'rwp',
    default => sub { { N => 'N', I => 'N', S => 'S' } },
);
has '+_needs_eol' => (
    is      => 'rwp',
    default => 1,
);

use namespace::clean;

=begin pod_coverage

=head3 setup

=end pod_coverage

=cut

sub setup {

    my $self = shift;

    $self->say( join( "\t", @{ $self->output_fields } ) );
    $self->say( join( "\t", @{ $self->output_types }{ @{ $self->output_fields } } ) );

}

=begin pod_coverage

=head3 encode

=end pod_coverage

=cut

sub encode {
    my $self = shift;

    no warnings 'uninitialized';
    join( "\t", @{ $_[0] }{ @{ $self->output_fields } } );
}

with 'Data::Record::Serialize::Role::Encode';

1;


__END__

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'rdb', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::rdb> encodes a record as
L<RDB|http://compbio.soe.ucsc.edu/rdb>.

It performs the L<B<Data::Record::Serialize::Role::Encode>> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<B<Data::Record::Serialize-E<gt>new>|Data::Record::Serialize/new>:
