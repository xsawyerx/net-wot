package Net::WOT;
# ABSTRACT: Access Web of Trust (WOT) API

use Carp;
use Moose;
use XML::Twig;
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
        0 => 'trustworthiness',
        1 => 'vendor_reliability',
        2 => 'privacy',
        4 => 'child_safety',
    } },

    handles => {
        get_component_name      => 'get',
        get_all_component_names => 'values',
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
    foreach my $item ( qw/ score confidence / ) {
        my $attr_name = "${comp}_$item";
        has $attr_name => ( is => 'rw', isa => 'Int' );
    }

    has "${comp}_description" => ( is => 'rw', isa => 'Str' );
}

sub _build_useragent {
    my $self = shift;
    my $lwp  = LWP::UserAgent->new();

    return $lwp;
}

sub _create_link {
    my ( $self, $target ) = @_;
    my $version  = $self->version;
    my $api_base = $self->api_base_url;
    my $api_path = $self->api_path;
    my $link     = "http://$api_base/$version/$api_path?target=$target";

    return $link;
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

        my $component_name = $self->get_component_name($component);

        # component: 0
        # confidence: 34
        # reputation: 30
        # trustworthiness_reputation
        # trustworthiness_description
        # trustworthiness_confidence

        my $score_attr = "${component_name}_score";
        $self->$score_attr($reputation);

        my $conf_attr = "${component_name}_confidence";
        $self->$conf_attr($confidence);

        my @rep_levels = sort { $b <=> $a } $self->get_reputation_levels;
        my $desc_attr  = "${component_name}_description";

        foreach my $reputation_level (@rep_levels) {
            if ( $reputation >= $reputation_level ) {
                my $rep_desc
                    = $self->get_reputation_description($reputation_level);

                $self->$desc_attr($rep_desc);

                last;
            }
        }
    }

    return $self->_create_reputation_hash;
}

sub _create_reputation_hash {
    my $self = shift;
    my %hash = ();

    foreach my $component ( $self->get_all_component_names ) {
        foreach my $item ( qw/ score description confidence / ) {
            my $attr  = "${component}_$item";
            my $value = $self->$attr;

            $value and $hash{$component}{$item} = $value;
        }
    }

    return %hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

This module provides an interface to I<Web of Trust>'s API.

    use Net::WOT;

    my $wot = Net::WOT->new;

    # get all details
    my %all_details = $wot->get_reputation('example.com');

    # use specific details after get_reputations() method was called
    print $wot->privacy_score, "\n";

=head1 EXPORT

Fully object oriented, nothing is exported.

=head1 ATTRIBUTES

Will document soon.

=head1 SUBROUTINES/METHODS

Will document soon.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

Please report bugs and other issues on the bugtracker:

L<http://github.com/xsawyerx/net-wot/issues>

=head1 SUPPORT

Hopefully.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

