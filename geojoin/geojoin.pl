#!/usr/bin/env perl

use warnings;
use strict;

use Irssi;
use vars qw($VERSION %IRSSI);

use Geo::IP;

# set up geoip city records file and irssi vars
my $city_recfile        = '/usr/local/share/GeoIP/GeoLiteCity.dat';
my $use_city_records    = 'false';
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
my @watchlist   = ( '#geoip_test' );

#### START #####
&init();

##### INIT SUBS #####
sub init {
    &info("version $VERSION");
    &check_db();
    if ($enabled == 1) {
        Irssi::signal_add('message join', 'channel_join');
    }
}

sub check_db {
    if ( $use_city_records && ( ! -s $city_recfile ) ) { 
        &warn("want to use city records but $city_recfile not found!");
        $enabled = 1;
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
        if ($watchlist[$idx] =~ /$rm_chan/) {
            splice(@watchlist, $idx, 1);
            &info("removed $rm_chan from list of monitored channels");
            return;
        }
    }

}

sub watching {
    my ($channel) = @_;

    for (@watchlist) {
        &info("checking $_ against $channel");
        return 1 if /$channel/ ;
    }
    return 0;
}


##### UTILITY SUBS #####
sub info {
    my ($message) = @_;
    Irssi::print("[+] geojoin: $message", Irssi::MSGLEVEL_CLIENTNOTICE);
}

sub warn {
    my ($message) = @_;
    Irssi::print("[!] geojoin: warning - $message", Irssi::MSGLEVEL_CLIENTNOTICE);
}


##### GeoIP functions #####
sub channel_join {
    my ($server, $data, $nick, $address) = @_;
    if (&watching($data)) {
        my $host = $address;
        $host =~ s/.+@(.+)/$1/ ;

        if ($host =~ /\//) {
            &info("can't do lookup on hostmask $host, skipping");
        }
        else {
            if ("$use_city_records" eq "true") {
                &city_lookup($host);
            }
            else {
                &country_lookup($host);
            }
        }
    }
    else {
        &info("$data not being watched: @watchlist");
    }

}

sub country_lookup {
    my ($target_addr) = @_;
    my $country = "not found";

    my $gi = Geo::IP->new(GEOIP_STANDARD);

    if ($target_addr =~ /(\d{1,3}\.){3}\d{1,3}/) {
        $country = $gi->country_code_by_addr($target_addr);
    }
    else {
        $country = $gi->country_code_by_name($target_addr);
    }
    
    &info("$target_addr: $country");
}
