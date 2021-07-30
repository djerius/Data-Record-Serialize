package Data::Record::Serialize::Role::Default;

# ABSTRACT:  Default methods for Data::Record::Serialize

use Moo::Role;

our $VERSION = '0.24';

use Hash::Util qw[ hv_store ];
use Ref::Util qw[ is_coderef ];

use Data::Record::Serialize::Error { errors => [ 'fields' ] }, -all;

use namespace::clean;

=for Pod::Coverage
 cleanup
 send
 setup
 DEMOLISH

=cut

=method B<send>

  $s->send( \%record );

Encode and send the record to the associated sink.

B<WARNING>: the passed hash is modified.  If you need the original
contents, pass in a copy.

=cut

# provide default if not already defined
sub send {
    my $self = shift;

    $self->_needs_eol
      ? $self->say( $self->encode( @_ ) )
      : $self->print( $self->encode( @_ ) );
}

# just in case they're not defined in preceding roles
sub setup { }
sub _map_types { }
sub _use_integer { 1 }
sub _numify { 0 }
sub _needs_eol { 1 }

around 'setup' => sub {
    my ( $orig, $self, $data ) = @_;

    # if fields has not been set yet, set it to the names in the data
    $self->_set_fields( [ keys %$data ] )
      unless $self->has_fields;

    # make sure there are no duplicate output fields
    my %dups;
    $dups{$_}++ && error( fields => "duplicate output field: $_" ) for@{$self->fields};

    if ( $self->has_default_type ) {
        $self->_set_types_from_default;
    }
    else {
        $self->_set_types_from_record( $data );
    }

    $orig->( $self );

    $self->_set__run_setup( 0 );
};


before 'send' => sub {
    my ( $self, $data ) = @_;

    # can't do format or numify until we have types, which might need to
    # be done from the data, which will be done in setup.

    $self->setup( $data )
      if $self->_run_setup;

    # remove fields that won't be output
    delete @{$data}{ grep { !defined $self->_fieldh->{$_} } keys %{$data} };

    # nullify fields (set to undef) those that are zero length

    if ( defined( my $nullify = $self->_nullify ) ) {
        $data->{$_} = undef
          for grep { defined $data->{$_} && !length $data->{$_} } @$nullify;
    }

    if ( my $format = $self->_format ) {
        $data->{$_}
          = is_coderef( $format->{$_} )
          ? $format->{$_}( $data->{$_} )
          : sprintf( $format->{$_}, $data->{$_} )
          foreach grep { defined $data->{$_} && length $data->{$_} }
          keys %{$format};
    }

    if ( $self->_numify ) {
        $_ = ( $_ || 0 ) + 0 foreach @{$data}{ @{ $self->numeric_fields } };
    }

    if ( my $rename = $self->rename_fields ) {
        for my $from ( @{ $self->fields } ) {
            my $to = $rename->{$from}
              or next;

            hv_store( %$data, $to, $data->{$from} );
            delete $data->{$from};
        }
    }
};

sub DEMOLISH {
    $_[0]->close;
    return;
}

1;

# COPYRIGHT

__END__


=head1 DESCRIPTION

C<Data::Record::Serialize::Role::Default> provides default methods for
L<Data::Record::Serialize>.  It is applied after all of the other roles to
ensure that other roles' methods have priority.

