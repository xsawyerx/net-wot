#!perl

use strict;
use warnings;

use Test::More tests => 15;

use Net::WOT;

my $wot = Net::WOT->new;
isa_ok( $wot, 'Net::WOT' );

my $xml = '<?xml version="1.0" encoding="UTF-8"?>' .
          '<query target="example.com">'           .
          '<application name="0" r="93" c="65"/>'  .
          '<application name="1" r="92" c="64"/>'  .
          '<application name="2" r="91" c="63"/>'  .
          '<application name="4" r="90" c="62"/>'  .
          '</query>';

{
    no warnings qw/redefine once/;
    *Net::WOT::_request_wot = sub {
        isa_ok( $_[0], 'Net::WOT' );
        is( $_[1], 'example.com', 'requesting WOT for example.com' );
        return $xml,
    }
}

my %expected_results = (
    trustwortiness => {
        score       => 93,
        confidence  => 65,
        description => 'excellent',
    },

    vendor_reliability => {
        score       => 92,
        confidence  => 64,
        description => 'excellent',
    },

    privacy => {
        score       => 91,
        confidence  => 63,
        description => 'excellent',
    },

    child_safety => {
        score       => 90,
        confidence  => 62,
        description => 'excellent',
    },
);

is_deeply(
    \%expected_results,
    \$wot->get_reputations('example.com'),
    'correct reputations',
);


my @items = qw/ trustworthiness vendor_reliability privacy child_safety /;

foreach my $component ( keys %expected_results ) {
    foreach my $item (@items) {
        my $value  = $expected_results{$component}{$item};
        my $method = "${component}_${item}";

        if ( $value =~ /^\d+$/ ) {
            # check number
            ok_cmp( $value, '==', $wot->$method, "$item for $component" );
        } else {
            # check string
            is( $value, $wot->$method, "$item for $component" );
        }
    }
}

