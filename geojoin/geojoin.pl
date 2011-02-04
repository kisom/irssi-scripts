#!/usr/bin/env perl

use warnings;
use strict;

use Irssi;
use vars qw($VERSION %IRSSI);

use Geo::IP;

# set up geoip city records file and irssi vars
my $geocity_recfile = '/usr/local/share/GeoIP/GeoLiteCity.dat';
$VERSION    = '0.1-alpha';
%IRSSI      = (
    authors             => 'kyle isom',
    origauthors         => 'kyle isom',
    contact             => 'coder@kyleisom.net',
    name                => 'geojoin.pl',
    description         => 'perform geoip city record lookups on joins ' +
                           'in specified channels',
    license             => 'dual-licensed public domain / ISC',
    url                 => 'http://www.brokenlcd.net',
);



