#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Net::WOT;

my $wot = Net::WOT->new;
isa_ok( $wot, 'Net::WOT' );

{
    no warnings qw/redefine once/;
    *Net::WOT::_create_link = sub {
        my ( $self, $target ) = @_;
        isa_ok( $self, 'Net::WOT' );
        is( $target, 'test_target', 'correct target sent to _create_link' );
    };
}

$wot->fetch_reputation('test_target');
