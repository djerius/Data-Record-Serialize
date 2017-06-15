package Data::Record::Serialize::Role::Default;

use Moo::Role;

our $VERSION = '0.13';

use Hash::Util qw[ hv_store ];

use namespace::clean;


# provide default if not already defined
sub send {

    my $self = shift;

    $self->_needs_eol
      ? $self->say( $self->encode( @_ ) )
      : $self->print( $self->encode( @_ ) );
}

# provide default if not already defined
sub setup { }

around 'setup' => sub {

    my ( $orig, $self, $data ) = @_;

    # if fields has not been set yet, set it to the names in the data
    $self->_set_fields( [ keys %$data ] )
      unless $self->fields;

    # create types on the fly from the first record if required
    $self->_set_types_from_record( $data )
      if $self->_need_types && !$self->types;

    $orig->( $self );

    $self->_set__run_setup( 0 );

};


before 'send' => sub {

    my ( $self, $data ) = @_;


    # can't do format or numify until we have types, which might need to
    # be done from the data, which will be done in setup.

    $self->setup( $data )
      if $self->_run_setup;

    delete @{$data}{ grep { !defined $self->_fieldh->{$_} } keys %{$data} };

    if ( $self->_format ) {

        my $format = $self->_format;

        $data->{$_} = sprintf( $format->{$_}, $data->{$_} )
          foreach grep { defined $data->{$_} && length $data->{$_} }
          keys %{$format};

    }

    if ( $self->_numify ) {

        $_ = ( $_ || 0 ) + 0 foreach @{$data}{ @{ $self->numeric_fields } };

    }

    if ( $self->rename_fields ) {

        my $rename = $self->rename_fields;

        for my $from ( @{ $self->fields } ) {

            my $to = $rename->{$from}
              or next;

            hv_store( %$data, $to, $data->{$from} );
            delete $data->{$from};
        }

    }

};


1;

__END__

=begin pod_coverage

=head3 cleanup

=head3 send

=head3 setup

=end pod_coverage

