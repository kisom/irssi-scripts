#!/usr/bin/env perl

use warnings;
use strict;

use Irssi;
use vars qw($VERSION %IRSSI);

use Geo::IP;
use Geo::IP::Record;

# set up geoip city records file and irssi vars
my $city_recfile        = '/usr/local/share/GeoIP/GeoLiteCity.dat';
my $use_city_records    = 'false';
my $enabled             = 0;
$VERSION    = '0.1-beta';
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
    if ("$use_city_records" eq "true") {
        &check_db();
    }
    Irssi::signal_add('message join', 'channel_join');
    Irssi::command_bind geojoin => \&geojoin_command ;
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

    if (! @watchlist) {
        push(@watchlist, $new_channel);
        &info("$new_channel added to watchlist");
        return;
    }
    
    foreach (@watchlist) {
        last if /^$new_channel$/ ;
        push(@watchlist, $new_channel);
        &info("$new_channel added to watchlist");
        return; 
    } 

    &info("$new_channel already being monitored!");
    return;
}

sub del_channel {
    my ($rm_chan) = @_;

    my $pre_chan = @watchlist;

    for (my $idx = 0; $idx < @watchlist; $idx++) {
        if ($watchlist[$idx] =~ /$rm_chan/) {
            splice(@watchlist, $idx, 1);
            &info("removed $rm_chan from list of monitored channels");
            return;
        }
    }

}

sub watching {
    my ($channel) = @_;

    for (@watchlist) { return 1 if /^$channel$/ ; }
    return 0;
}


##### UTILITY SUBS #####
sub info {
    my ($message) = @_;
    Irssi::print("[+] geojoin: $message", Irssi::MSGLEVEL_CLIENTNOTICE);
}

sub chan_info {
    my ($msg, $srv, $chan) = @_;
    $srv->print($chan, "[+] geojoin: $msg", Irssi::MSGLEVEL_CLIENTNOTICE);
}

sub warn {
    my ($message) = @_;
    Irssi::print("[!] geojoin: warning - $message", Irssi::MSGLEVEL_CLIENTNOTICE);
}


##### GeoIP functions #####
sub channel_join {
    return if !$enabled ;
    my ($server, $chan, $nick, $address) = @_;

    if (&watching($chan)) {
        my $host = $address;
        $host =~ s/.+@(.+)/$1/ ;

        if ($host =~ /\//) {
            &info("can't do lookup on hostmask $host, skipping");
        }
        else {
            if ("$use_city_records" eq "true") {
                my $record = &city_lookup($host);
                &chan_info("$nick joining from $host via { city: " . 
                           $record->city . ", "  .
                           "region: " . $record->region . ", country; " .
                           $record->country_code . ", timezone: " .
                           $record->time_zone . " }", $server, $chan);
            }
            else {
                my $country = &country_lookup($host, $server, $chan);
                &chan_info("$nick joining from $host via $country", $server, 
                           $chan);
            }
        }
    }
    else {
        &chan_info("$nick joining with hostmask, skipping geoip lookup...");
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
    
    return $country;
}

sub city_lookup {
    my ($target_addr) = @_;
    my $gi = Geo::IP->open($city_recfile, GEOIP_STANDARD);
    my $record = "";

    if ($target_addr =~ /(\d{1,3}\.){3}\d{1,3}/) {
        $record = $gi->record_by_addr($target_addr);
    }
    else {
        $record = $gi->record_by_name($target_addr);
    }
    
    return $record;

       
}

sub geojoin_command {
    my ($argline, $server) = @_ ;
    my ($command, @args)   = split(/ /, $argline);
    $command = lc($command);
    
    if ("$command" eq "add" ) {
        foreach (@args) {
            &add_channel($_);
        }
    } 
    elsif ("$command" eq "del") {
        foreach (@args) {
            &del_channel($_);
        }
    }
    elsif ("$command" eq "status") {
        &info("geojoin v$VERSION status:");

        if ($enabled == 1) { &info("GeoIP lookups enabled"); }
        else { &info("GeoIP lookups disabled"); }

        if ("$use_city_records" eq 'true') {
            &info("using city records");
        }
        else {
            &info("using country records");
        }

        &info("channel list:");
        foreach (@watchlist) {
            &info("    $_", Irssi::MSGLEVEL_CLIENTNOTICE);
        }
    }
    elsif ("$command" eq "clear") {
        @watchlist = ( );
        $enabled = 0;
    }
    elsif ("$command" eq "disable") { $enabled = 0; }
    elsif ("$command" eq "enable")  { $enabled = 1; }
    elsif ("$command" eq "use_country") { $use_city_records = 'false'; }
    elsif ("$command" eq "use_city") { 
        $use_city_records = 'true'; 
        &check_db(); 
    }
    elsif ("$command" eq "set_citydb") { 
        $city_recfile = $args[0];
        &check_db();
    }
    elsif ("$command" eq "help") { 
        &info("help and usage:");
        my $help_msg = <<END_HELP;
geojoin checks specified channels for joins and performs GeoIP lookups on connecting hosts. by default it uses country lookups.
command list:
    add <channel list>      add channels to watchlist
    del <channel list>      remove channel from watchlist
    disable                 disable geojoin
    enable                  enable geojoin
    use_country             use country lookups (default)
    use_city                use city lookups 
    status                  view current status
END_HELP
        &info($help_msg); 
   } 
}
