#!/usr/bin/env perl

use warnings;
use strict;

use Irssi;
use vars qw($VERSION %IRSSI);

use Geo::IP;

# set up geoip city records file and irssi vars
my $city_recfile        = '/usr/local/share/GeoIP/GeoLiteCity.dat';
my $use_city_records    = 'true';
my $enabled             = 0;
$VERSION    = '0.1-alpha';
%IRSSI      = (
    authors             => 'kyle isom',
    origauthors         => 'kyle isom',
    contact             => 'coder@kyleisom.net',
    name                => 'geojoin.pl',
    description         => 'perform geoip city record lookups on joins ' .
                           'in specified channels',
    license             => 'dual-licensed public domain / ISC',
    url                 => 'http://www.brokenlcd.net',
);

# set up script variables
Irssi::settings_add_str('geojoin', 'use_city_records', $use_city_records);
Irssi::settings_add_str('geojoin', 'city_record_file', $city_recfile);
my @watchlist   = ( );

#### START #####
&init();

##### INIT SUBS #####
sub init {
    &info("version $VERSION");
    &check_db();
}

sub check_db {
    if ( $use_city_records && ( ! -s $city_recfile ) ) { 
        &warn("want to use city records but $city_recfile not found!");
        $enabled = 0;
        return;
    }

    else {
        $enabled = 1;
    }
}

##### SETTING SUBS #####

# add a channel to the watch list
sub add_channel {
    my ($new_channel) = @_;
    
    if (grep($new_channel, @watchlist)) {
        &info("$new_channel already being monitored!");
        return;
    } 

    else {
        push(@watchlist, $new_channel);
        &info("$new_channel added to watchlist");
        return; 
    }
}

sub del_channel {
    my ($rm_chan) = @_;

    my $pre_chan = @watchlist;

    for (my $idx = 0; $idx < $#watchlist; $idx++) {
        if $watchlist[$idx] =~ /$rm_chan/ {
            splice(@watchlist, $idx, 1);
            &info("removed $rm_chan from list of monitored channels");
    }

}


##### UTILITY SUBS #####
sub info {
    my ($message) = @_;
    Irssi::print("[+] geojoin: $message");
}

sub warn {
    my ($message) = @_;
    Irssi::print("[!] geojoin: warning - $message");
}


##### GeoIP functions #####
sub channel_join {
    

}
