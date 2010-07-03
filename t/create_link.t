#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Net::WOT;

my $wot  = Net::WOT->new( target => 'hello' );
my $link = $wot->_create_link;
my $api  = $wot->api_base_url;
my $path = $wot->api_path;
my $ver  = $wot->version;

is(
    $link,
    "$api/$ver/$path?target=hello",
    'correct path created with target attr',
);

$wot  = Net::WOT->new( url => 'urlhello' );
$link = $wot->_create_link;

is(
    $link,
    "$api/$ver/$path?target=urlhello",
    'correct path created with url attr',
);

