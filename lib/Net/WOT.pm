package Net::WOT;
# ABSTRACT: Access Web of Trust (WOT) API

use Carp;
use Moose;
use URI::FromHash;
use namespace::autoclean;

has api_base_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://api.mywot.com/'
);

has target => (
    is  => 'ro',
    isa => 'Str',
    predicate => 'has_target',
);

has url => (
    is  => 'ro',
    isa => 'Str',
    predicate => 'has_url',
);

sub BUILD {
    my $self = shift;
    if ( ! $self->has_target && ! $self->has_url ) {
        croak 'target or url required';
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
