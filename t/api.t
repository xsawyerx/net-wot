#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Net::WOT;

my $wot = Net::WOT->new;
isa_ok( $wot, 'Net::WOT' );

