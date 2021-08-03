package Data::Record::Serialize::Util;

# ABSTRACT: Useful things

use strict;
use warnings;
our $VERSION = '0.24';

use parent 'Exporter::Tiny';

my @TYPE_CATEGORY_NAMES;
my %TYPES;
BEGIN {
    @TYPE_CATEGORY_NAMES = qw(
      ANY
      INTEGER
      FLOAT
      NUMBER
      STRING
      NOT_STRING
      BOOLEAN
    );

    %TYPES = (
        T_INTEGER        => 'I',
        T_NUMBER         => 'N',
        T_STRING         => 'S',
        T_BOOLEAN        => 'B',
    );
}

use enum @TYPE_CATEGORY_NAMES;
use constant \%TYPES;

our @TYPE_CATEGORIES = map {;  # add a ; to help 5.10
    no strict 'refs'; ## no critic(ProhibitNoStrict)
    $_->();
} @TYPE_CATEGORY_NAMES;

our %EXPORT_TAGS = (
    types     => [ keys %TYPES ],
    categories => \@TYPE_CATEGORY_NAMES,
    subs       => [ qw( is_type index_types ) ],
);

our @EXPORT_OK = map { @{$_} } values %EXPORT_TAGS;

my @TypeRE;
$TypeRE[ $_->[0] ] = $_->[1]
  for
  [ ANY             ,=> qr/.*/     ],
  [ STRING          ,=> qr/^S/i    ],
  [ FLOAT           ,=> qr/^N/i    ],
  [ INTEGER         ,=> qr/^I/i    ],
  [ BOOLEAN         ,=> qr/^B/i    ],
  [ NUMBER          ,=> qr/^[NI]/i ],
  [ NOT_STRING      ,=> qr/^[^S]+/ ];

sub is_type {
    my ( $type, $type_enum ) = @_;
    $type =~ $TypeRE[$type_enum];
}

sub index_types {
    my ( $types ) = @_;

    my @fields = keys %$types;
    my @type_index;

    for my $category ( @TYPE_CATEGORIES ) {
        my $re = $TypeRE[$category];
        $type_index[$category] = [ grep { $types->{$_} =~ $re } @fields ];
    }

    return \@type_index;
}

1;

# COPYRIGHT

__END__

=for Pod::Coverage
index_types
is_type
