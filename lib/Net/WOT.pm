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
        get_reputation_levels      => 'keys',
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

# automatically create all reputation component attributes
foreach my $comp ( qw/
        trustworthiness
        vendor_reliability
        privacy
        child_safety
        reputation
    / ) {
    foreach my $item ( qw/ score confidence description / ) {
        my $attr_name = "${comp}_${item}";
        has $attr_name => ( is => 'rw', isa => 'Int' );
    }
}

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

# <?xml version="1.0" encoding="UTF-8"?>
# <query target="google.com">
#     <application c="93" name="0" r="94"/>
#     <application c="92" name="1" r="95"/>
#     <application c="88" name="2" r="93"/>
#     <application c="88" name="4" r="93"/>
# </query>

sub _request_wot {
    my ( $self, $target ) = @_;
    my $link     = $self->_create_link($target);
    my $response = $self->ua_get($link);
    my $status   = $response->status_line;

    $response->is_success or croak "Can't get reputation: $status\n";

    return $response->content;
}

sub get_reputation {
    my ( $self, $target ) = @_;
    my $xml  = $self->_request_wot($target);
    my $twig = XML::Twig->new();

    $twig->parse($xml);

    my @children = $twig->root->children;
    foreach my $child (@children) {
        # checking a specific query
        my $component  = $child->att('name');
        my $confidence = $child->att('c');
        my $reputation = $child->att('r');

        # component: 0
        # confidence: 34
        # reputation: 30
        # trustworthiness_reputation
        # trustworthiness_description
        # trustworthiness_confidence

        my $conf_attr = $self->get_component_name($component) . '_confidence';
        $self->$conf_attr($confidence);

        my $desc_attr = $self->get_component_name($component) . '_description';
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
