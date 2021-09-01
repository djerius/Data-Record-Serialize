package Data::Record::Serialize::Encode::json;

# ABSTRACT: encoded a record as JSON

use strict;
use warnings;

use Data::Record::Serialize::Error { errors => [ 'json_backend' ] }, -all;

use Moo::Role;

our $VERSION = '0.30';


BEGIN {
    my $Cpanel_JSON_XS_VERSION = 3.0236;

    if ( eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->VERSION( $Cpanel_JSON_XS_VERSION ); 1;  } ) {
        *encode_json = \&Cpanel::JSON::XS::encode_json;
    }
    elsif ( eval { require JSON::PP } ) {
        *encode_json = \&JSON::PP::encode_json;
    }
    else {
        error( 'json_backend', "can't find either Cpanel::JSON::XS (>= $Cpanel_JSON_XS_VERSION) or JSON::PP. Please install one of them." );
    }
};

use namespace::clean;

has '+numify' => ( is => 'ro', default => 1 );
has '+stringify' => ( is => 'ro', default => 1 );

sub _needs_eol { 1 }

=method to_bool

   $bool = $self->to_bool( $truthy );

Convert a truthy value to something that the JSON encoders will recognize as a boolean.

=cut

sub to_bool { $_[1] ? \1 : \0 }

=for Pod::Coverage
  encode

=cut

sub encode { encode_json( $_[1] ) }

with 'Data::Record::Serialize::Role::Encode';

1;

# COPYRIGHT

__END__

=for Pod::Coverage
numify
stringify
encode_json

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'json', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::json> encodes a record as JSON.

If a field's type is C<N> or C<I>, it will be properly encoded by JSON
as a number.  Field's with type C<S> are force to be strings.

Boolean fields (type C<B>) are transformed into values recognized by
the back-end encoder.

The output consists of I<concatenated> JSON objects, and is mostly easily
read by an incremental decoder, e.g.

  use JSON::MaybeXS;

  @data = JSON->new->incr_parse( $json );

It performs the L<Data::Record::Serialize::Role::Encode> role.


=head1 INTERFACE

There are no additional attributes which may be passed to
L<< Data::Record::Serialize::new|Data::Record::Serialize/new >>.
