#!/usr/bin/env perl
# geojoin.pl
# author: 4096r/b7b720d6  "kyle isom <coder@kyleisom.net>"
# license: dual isc / public domain
# usage: 
#   load script with '/load /path/to/geojoin.pl'
#   list commands with '/geojoin /help'

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

my @watchlist   = ( '#geoip_test' );

#### START #####
&init();

##### INIT SUBS #####


##### channel subs #####

# add a channel to the watch list
sub add_channel {
    my ($new_channel) = @_;

    # needed for empty list
    # code duplication, need to figure out the code simplification
    if (! @watchlist) {
        push(@watchlist, $new_channel);
        &info("$new_channel added to watchlist");
        return;
    }
    
    foreach (@watchlist) {
        last if /^$new_channel$/ ;                  # abort if channel in list
        push(@watchlist, $new_channel);
        &info("$new_channel added to watchlist");
        return; 
    } 

    &info("$new_channel already being monitored!");
    return;
}

# remove channel from watch list
sub del_channel {
    my ($rm_chan) = @_;

    my $pre_chan = @watchlist;

    for (my $idx = 0; $idx < @watchlist; $idx++) {
        if ($watchlist[$idx] =~ /^$rm_chan$/) {
            splice(@watchlist, $idx, 1);
            &info("removed $rm_chan from list of monitored channels");
            return;
        }
    }

}

# test a channel to see if it's in the watch list
sub watching {
    my ($channel) = @_;

    for (@watchlist) { return 1 if /^$channel$/ ; }
    return 0;
}


##### messaging subs #####
# print information message with geojoin preface to status window
sub info {
    my ($message) = @_;
    return if $message =~ /^$/ ;        # abort empty message
    Irssi::print("[+] geojoin: $message", Irssi::MSGLEVEL_CLIENTNOTICE);
}

# print information message to a specific channel
sub chan_info {
    my ($msg, $srv, $chan) = @_;
    return if $msg =~ /^$/ ;            # abort empty message
    return if (! $srv or ! $chan );     # abort on bad server / channel
    $srv->print($chan, "[+] geojoin: $msg", Irssi::MSGLEVEL_CLIENTNOTICE);
}

# similar to info but has warning preface
sub warn {
    my ($message) = @_;
    Irssi::print("[!] geojoin: warning - $message", Irssi::MSGLEVEL_CLIENTNOTICE);
}


##### GeoIP functions #####
# triggered on channel join
# determines if it should / could do a geoip lookup on a joining user, and when
# appropriate, performs the lookup
sub channel_join {
    return if !$enabled ;
    my ($server, $chan, $nick, $address) = @_;

    if (&watching($chan)) {
        my $host = $address;
        $host =~ s/.+@(.+)/$1/ ;        # address in the form user@host

        if ($host =~ /\//) {            # a / in the address indicates hostmask
            &info("can't do lookup on hostmask $host, skipping");
        }
        else {
            &chan_info('*** geoip lookup ***', $server, $chan);
            if ("$use_city_records" eq "true") {
                my $record = &city_lookup($host);
                # nasty blob that prints useful city record information
                &chan_info("$nick joining from $host via { city: " . 
                           $record->city . ", "  .
                           "region: " . $record->region . ", country: " .
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

# country record lookups
sub country_lookup {
    my ($target_addr) = @_;
    my $country = "not found";

    my $gi = Geo::IP->new(GEOIP_STANDARD);

    # look for ip address
    if ($target_addr =~ /^(\d{1,3}\.){3}\d{1,3}$/) {
        $country = $gi->country_code_by_addr($target_addr);
    }
    else {      # lookups by name are sweet
        $country = $gi->country_code_by_name($target_addr);
    }
    
    return $country;
}

# city record lookups
sub city_lookup {
    my ($target_addr) = @_;
    my $gi = Geo::IP->open($city_recfile, GEOIP_STANDARD);
    my $record = "";

    # look for ip address
    if ($target_addr =~ /(\d{1,3}\.){3}\d{1,3}/) {
        $record = $gi->record_by_addr($target_addr);
    }
    else {
        $record = $gi->record_by_name($target_addr);
    }
    
    return $record;

       
}

##### c2 subs #####

# contains /geojoin command parsing and handling
sub geojoin_command {
    my ($argline, $server) = @_ ;
    my ($command, @args)   = split(/ /, $argline);
    $command = lc($command);            # irc commands shouldn't be case 
                                        # sensitive
    
    if ("$command" eq "add" ) {         # add channel
        foreach (@args) {
            &add_channel($_);
        }
    } 
    elsif ("$command" eq "del") {       # del channel
        foreach (@args) {
            &del_channel($_);
        }
    }
    elsif ("$command" eq "status") {    # script status 
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
    elsif ("$command" eq "clear") {     # clear channel list
        @watchlist = ( );
        $enabled = 0;
        &info("cleared watchlist and disabled script");
    }
    elsif ("$command" eq "disable") {   # disable script
        $enabled = 0; 
        &info("disabled");
    }
    elsif ("$command" eq "enable")  {   # enable script
        $enabled = 1; 
        &info("enabled");
    }
    elsif ("$command" eq "use_country") {
        $use_city_records = 'false';    # use country lookups
        &info("using country record lookups");
    }
    elsif ("$command" eq "use_city") {  # use city record lookups
        $use_city_records = 'true'; 
        &check_db();        # need to check for a valid database 
        if ($enabled == 0) {
            &warn("error loading city record $city_recfile");
            &warn("geojoin disabled!");
        }
        else {
            &info("using city record lookups");
            &info("city record database: $city_recfile");
        }
    }
    elsif ("$command" eq "set_citydb") {
        $city_recfile = $args[0];       # set city database
        &check_db();
    }
    elsif ("$command" eq "help") {      # get help
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

# initialisation sub - print version, check database, register signal handlers
sub init {
    &info("version $VERSION");
    if ("$use_city_records" eq "true") {
        &check_db();
    }
    else { $enabled = 1; }
    Irssi::signal_add_last('message join', 'channel_join');
    Irssi::command_bind geojoin => \&geojoin_command ;
}

# simple city record database check - just check to see if it has a nonzero
# size. a bad db will still caused the geoip functions to choke.
sub check_db {
    if ( $use_city_records && ( ! -s $city_recfile ) ) { 
        &warn("want to use city records but $city_recfile not found!");
        $enabled = 0;       # disable geoip looks on validation failure
    }

    else { $enabled = 1; }  # enable geoip lookups if simple validation passed
}

