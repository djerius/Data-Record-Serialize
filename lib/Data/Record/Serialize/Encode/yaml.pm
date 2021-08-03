package Data::Record::Serialize::Encode::yaml;

# ABSTRACT: encode a record as YAML

use Moo::Role;

use Data::Record::Serialize::Error { errors => [ 'yaml_backend' ] }, -all;
use Types::Standard qw[ Enum ];

our $VERSION = '0.25';

use JSON::PP;

use namespace::clean;

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

has _backend => ( is => 'ro',
                  init_arg => 'backend',
                 isa => Enum[ 'YAML::XS', 'YAML::PP' ],
                 builder => 1
               );

sub _build__backend {

    if ( eval { require YAML::XS } ) {
        'YAML::XS';
    }
    elsif ( eval { require YAML::PP } ) {

        'YAML::PP'
    }
    else {
        error( 'yaml_backend', "can't find either YAML::XS or YAML::PP. Please install one of them" );
    }
}


has _encode => ( is => 'lazy',
                 init_arg => undef,
                 builder => 1
               );

sub _build__encode {
    my $self = shift;

    if ( $self->_backend eq 'YAML::PP' ) {
        my $processor = YAML::PP->new( boolean => 'JSON::PP' );
        sub { shift; $processor->dump_string( @_ ) };
    }
    elsif ( $self->_backend eq 'YAML::XS' ) {
        sub { local $YAML::XS::Boolean = 'JSON::PP';
              shift;
              YAML::XS::Dump( @_ );
          }
    }
}


sub encode { shift->_encode->(@_) }

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
