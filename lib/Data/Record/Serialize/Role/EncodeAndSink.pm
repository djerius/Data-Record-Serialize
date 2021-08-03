package Data::Record::Serialize::Role::EncodeAndSink;

# ABSTRACT: Both an Encode and Sink. handle unwanted/unused required routines

use Data::Record::Serialize::Error { errors => [ qw( internal  ) ] }, -all;

use namespace::clean;

use Moo::Role;

( *say, *print, *encode ) = map {
    my $stub = $_;
    sub { error ( 'internal', "internal error: stub method <$stub> invoked" ) }
} qw( say print encode );

sub close {}

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';

1;

