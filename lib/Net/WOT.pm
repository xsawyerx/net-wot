package Net::WOT;
# ABSTRACT: Access Web of Trust (WOT) API

use Carp;
use Moose;
use XML::Twig;
use URI::FromHash 'uri';
use LWP::UserAgent;
use namespace::autoclean;

# useragent to work with
has 'useragent' => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    handles    => { ua_get => 'get' },
    lazy_build => 1,
);

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

has components => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        1 => 'trustworthiness',
        2 => 'vendor_reliability',
        3 => 'privacy',
        4 => 'child_safety',
    } },

    handles => {
        get_component_name       => 'get',
        get_all_components_names => 'values',
    },
);

has reputation_levels => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        80 => 'excellent',
        60 => 'good',
        40 => 'unsatisfactory',
        20 => 'poor',
         0 => 'very poor',
    } },

    handles => {
        get_reputation_description => 'get',
    },
);

has confidence_levels => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        45 => '5',
        34 => '4',
        23 => '3',
        12 => '2',
         6 => '1',
         0 => '0',
    } },

    handles => {
        get_confidence_level      => 'get',
        get_all_confidence_levels => 'values',
    },
);

has maximum_confidence_level => ( is => 'ro', isa => 'Int', default => 5 );

has [ qw/ trustworthiness vendor_reliability privacy child_safety reputation / ]
    => ( is => 'rw', isa => 'Int' );

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

sub get_reputation {
    my ( $self, $target ) = @_;
    my $link     = $self->_create_link($target);
    my $response = $self->ua_get($link);

    $response->is_success or return;

    # <?xml version="1.0" encoding="UTF-8"?>
    # <query target="google.com">
    #     <application c="93" name="0" r="94"/>
    #     <application c="92" name="1" r="95"/>
    #     <application c="88" name="2" r="93"/>
    #     <application c="88" name="4" r="93"/>
    # </query>

    my $twig = XML::Twig->new();
    $twig->parse( $response->content );

    my @children = $twig->root->children;
    foreach my $child (@children) {
        my $c = $child->att('c');
    }

    return 1;
}

sub get_details {
    my $self  = shift;
    my %comps = ();

    foreach my $component ( $self->all_components ) {
        $comps{$component} = $self->$component || q{};
    }

    return %comps;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
