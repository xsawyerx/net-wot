package Net::WOT;
# ABSTRACT: Access Web of Trust (WOT) API

use Carp;
use Moose;
use URI::FromHash 'uri';
use LWP::UserAgent;
use namespace::autoclean;

# docs are at: http://www.mywot.com/wiki/API
has api_base_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'api.mywot.com',
);

has api_path => (
    is      => 'ro',
    isa     => 'Str',
    default => 'public_query2',
);

has version => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.4,
);

has reputations => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        1 => 'Trustworthiness',
        2 => 'Vendor reliability',
        3 => 'Privacy',
        4 => 'Child safety',
    } },

    handles => {
        get_reputation => 'get',
    },
);

has [ qw/ trustworthiness vendor_reliability privacy child_safety / ]
    => ( is => 'rw', isa => 'Int' );

has 'useragent' => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    handles    => ['get'],
    lazy_build => 1,
);

sub _build_useragent {
    my $self = shift;
    my $lwp  = LWP::UserAgent->new();

    return $lwp;
}

sub _create_link {
    my ( $self, $target ) = @_;
    my $version   = $self->version;
    my $api_base  = $self->api_base_url;
    my $api_path  = $self->api_path;
    my $base_path = "$api_base/$version/$api_path";

    my $link = uri(
        path  => $base_path,
        query => { target => $target },
    );

    return "http://$link";
}

sub fetch_reputation {
    my ( $self, $target ) = @_;
    my $link     = $self->_create_link($target);
    my $response = $self->get($link);

    $response->is_success or return;
}

sub get_details {
    my $self  = shift;
    my @attrs = qw/ trustworthiness vendor_reliability privacy child_safety /;
    my %attrs = ();

    foreach my $attr (@attrs) {
        $attrs{$attr} = $self->$attr || q{};
    }

    return %attrs;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
