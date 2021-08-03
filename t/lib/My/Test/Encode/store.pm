package My::Test::Encode::store;

use Moo::Role;

has output => ( is => 'ro',
                default => sub { [] }
              );

sub send {
    my $self = shift;
    push @{ $self->output }, @_;
}

with 'Data::Record::Serialize::Role::EncodeAndSink';

1;
