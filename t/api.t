#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use Net::WOT;

my $wot;

throws_ok { $wot = Net::WOT->new() } qr/^target or url required/,
    'requiring target or url';

lives_ok {
    $wot = Net::WOT->new( target => 'wha' );
    isa_ok( $wot, 'Net::WOT' );
    $wot = Net::WOT->new( url    => 'wah' );
    isa_ok( $wot, 'Net::WOT' );
} 'created using either target or url';

