package Data::Record::Serialize::Encode::yaml;

# ABSTRACT: encode a record as YAML

use Moo::Role;

use Data::Record::Serialize::Error { errors => [ 'yaml_backend' ] }, -all;
use Types::Standard qw[ Enum ];

use JSON::PP; # needed for JSON::PP::true/false

use namespace::clean;

our $VERSION = '0.33';

BEGIN {
    my $YAML_XS_VERSION = 0.67;

    if ( eval { require YAML::XS; YAML::XS->VERSION( $YAML_XS_VERSION ); 1; } )
    {
        *encode = sub {
            local $YAML::XS::Boolean = 'JSON::PP';
            YAML::XS::Dump( $_[1] );
          }
    }
    elsif ( eval { require YAML::PP } ) {
        my $processor = YAML::PP->new( boolean => 'JSON::PP' );
        *encode = sub { $processor->dump_string( $_[1] ) };
    }
    else {
        error( 'yaml_backend',
            "can't find either YAML::XS (>= $YAML_XS_VERSION) or YAML::PP. Please install one of them"
        );
    }
}

has '+numify' => ( is => 'ro', default => 1 );
has '+stringify' => ( is => 'ro', default => 1 );

sub _needs_eol { 1 }

=method to_bool

   $bool = $self->to_bool( $truthy );

Convert a truthy value to something that the YAML encoders will recognize as a boolean.

=cut

sub to_bool { $_[1] ? JSON::PP::true : JSON::PP::false }

=for Pod::Coverage
 encode

=cut

with 'Data::Record::Serialize::Role::Encode';

1;

# COPYRIGHT

__END__

=for Pod::Coverage
numify
stringify

=head1 SYNOPSIS

    use Data::Record::Serialize;

    my $s = Data::Record::Serialize->new( encode => 'yaml', ... );

    $s->send( \%record );

=head1 DESCRIPTION

B<Data::Record::Serialize::Encode::yaml> encodes a record as YAML.  It uses uses either L<YAML::XS> or L<YAML::PP>.

It performs the L<Data::Record::Serialize::Role::Encode> role.

=head1 CONSTRUCTOR OPTIONS

=over

=item backend => C<YAML::XS> | C<YAML::PP>

Optional. Which YAML backend to use.  If not specified, searches for one of the two.

=back
