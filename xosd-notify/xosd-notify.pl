#!/usr/bin/perl
# xosd-notify.pl
# author: kyle isom <coder@kyleisom.net>
# license: isc / public domain dual-license

use strict;
use warnings;

use Irssi;
use vars qw($VERSION %IRSSI);

use X::Osd;

# set up Irssi vars
$VERSION = '0.1-prealpha';

%IRSSI   = (
    authors         => 'kyle isom',
    origauthors     => 'kyle isom',
    contact         => 'coder@kyleisom.net',
    name            => 'xosd-notify.pl',
    description     => 'display hilights and pms via xosd',
    license         => 'dual isc / public domain',
    url             => 'http://www.brokenlcd.net/code/irssi/index.html',
);

my $num_lines       = 1;        # number of lines to use for the display
my $osd             = "";       # the on-screen display object
my $enabled         = 1;        # boolean flag


##### kick these shenanigans off #####
&init();


##### initialisation and configuration subs #####

sub init {
    # set up Irssi settings
    Irssi::settings_add_str('xosd-notify', 'xosd_font', 'fixed');
    Irssi::settings_add_str('xosd-notify', 'xosd_foreground', '#00FF00');
    Irssi::settings_add_str('xosd-notify', 'xosd_background', '#000000');
    Irssi::settings_add_str('xosd-notify', 'xosd_shadow_colour', '#111');
    Irssi::settings_add_str('xosd-notify', 'xosd_position', 'top-left');
    Irssi::settings_add_int('xosd-notify', 'xosd_timeout', 5);
    Irssi::settings_add_int('xosd-notify', 'xosd_border', 10); 
    Irssi::settings_add_int('xosd-notify', 'xosd_shadow_offset', 0);
    Irssi::settings_add_int('xosd-notify', 'xosd_voffset', 5);
    Irssi::settings_add_int('xosd-notify', 'xosd_hoffset', 5);

    # set up Irssi signal handlers
    Irssi::signal_add_last('window item hilight', 'win_hl');
    Irssi::signal_add_last('message private', 'event_privmsg'); # should take precedence

    # set up command handlers
    Irssi::command_bind xosd => \&xosd_cmd;

    $osd = X::Osd->new($num_lines); 
    &osd_setup();

}

sub osd_setup {
    &osd_config();
    $osd->string(0, "xosd-notify $VERSION loaded!");
    Irssi::print("xosd-notify $VERSION loaded!");
}

sub osd_config {
    my ($vert, $horiz) = &translate_position(Irssi::settings_get_str(
        'xosd_position'));

    # setup basic font and colour
    $osd->set_font(Irssi::settings_get_str('xosd_font'));
    $osd->set_colour(Irssi::settings_get_str('xosd_foreground'));

    # setup border
    $osd->set_outline_colour(Irssi::settings_get_str('xosd_background'));
    $osd->set_outline_offset(Irssi::settings_get_int('xosd_border'));

    # setup shadow
    $osd->set_shadow_offset(Irssi::settings_get_int('xosd_shadow_offset'));
    $osd->set_shadow_colour(Irssi::settings_get_str('xosd_shadow_colour'));

    # setup screen position
    $osd->set_pos($vert);
    $osd->set_align($horiz);

    # set the on-screen dwell-time
    $osd->set_timeout(Irssi::settings_get_int('xosd_timeout'));

    # set the horizontal / vertical offsets
    $osd->set_vertical_offset(Irssi::settings_get_int('xosd_voffset'));
    $osd->set_horizontal_offset(Irssi::settings_get_int('xosd_hoffset'));

    # osd should be done
    Irssi::print("xosd-notify $VERSION configured");
}

##### configuration file subs #####
sub save_settings {
    my ($conf_file) = @_ ;

    # load a sensible default
    if (! $conf_file) { $conf_file = "$ENV{HOME}/.irssi/.xosd-notifyrc"; }
    
    open(CONF, ">$conf_file") or $conf_file = "EXCEPTION";
    if ("$conf_file" eq "EXCEPTION") {
        &warn("error writing to $conf_file - $@");
        return ;
    }

    print CONF "# xosd-notify.pl irssi script saved configuration settings\n";
    print CONF "\nxosd_font: " . Irssi::settings_get_str('xosd_font');
    print CONF "\nxosd_foreground: ";
    print CONF Irssi::settings_get_str('xosd_foreground');
    print CONF "\nxosd_background: ";
    print CONF Irssi::settings_get_str('xosd_background');
    print CONF "\nxosd_shadow_colour: ";
    print CONF Irssi::settings_get_str('xosd_shadow_colour');
    print CONF "\nxosd_position: " . Irssi::settings_get_str('xosd_position');
    print CONF "\nxosd_timeout: ", Irssi::settings_get_int('xosd_timeout');
    print CONF "\nxosd_border: ", Irssi::settings_get_int('xosd_border');
    print CONF "\nxosd_shadow_offset: ";
    print CONF Irssi::settings_get_int('xosd_shadow_offset');
    print CONF "\nxosd_voffset: ", Irssi::settings_get_int('xosd_voffset');
    print CONF "\nxosd_hoffset: ", Irssi::settings_get_int('xosd_hoffset');
    print CONF "\n";

    close CONF;

    &info("config file written to $conf_file");
}


##### utility subs ######

sub translate_position {
    my ($position)  = @_ ;
    my $vert        = '';
    my $horiz       = '';

    $position = lc($position);

    # get vertical position
    if    ( $position =~ /^'top/ )      { $vert = XOSD_top; }
    elsif ( $position =~ /^'middle/ )   { $vert = XOSD_middle; }
    elsif ( $position =~ /^'center/ )   { $vert = XOSD_middle; }
    elsif ( $position =~ /^'bottom/ )   { $vert = XOSD_bottom; }
    else                                { $vert = XOSD_top; }       # default

    # get horizontal position
    if    ( $position =~ /right'$/ )    { $horiz = XOSD_right; }
    elsif ( $position =~ /left'$/ )     { $horiz = XOSD_left; }
    elsif ( $position =~ /center'$/ )   { $horiz = XOSD_center; }
    elsif ( $position =~ /middle'$/ )   { $horiz = XOSD_center; }
    else                                { $horiz = XOSD_left; }     # default

    return ($vert, $horiz);
}

# simple sub to print a message identifying this script as the source
# useful when a lot of status messages are being printed
sub info {
    my ($message) = @_;
    return if ! "$message";

    Irssi::print("[+] xosd-notify: $message");
}

# similar sub that adds a warning prefix
sub warn {
    my ($message) = @_ ;
    return if ! "$message";

    Irssi::print("[!] xosd-notify WARNING: $message");
}


##### event handlers ######

# these were really too easy
sub event_privmsg {
    return if ! $enabled;
    my ($server, $data, $nick, $address) = @_ ;
    $osd->string(0, "$nick: $data");
}

sub win_hl {
    return if ! $enabled ;
    my ($witem) = @_;
    $osd->string(0, "highlight in " . $witem->{ name } );
}


##### command and control subs ######

# command handler
sub xosd_cmd {
    my ($argline, $server) = @_ ;
    my ($command, @args)   = split(/ /, $argline);

    if ("$command" eq 'enable') {           # provide ability to enable xosd
        $osd->string(0, "xosd-notify enabled");
        $enabled = 1;
    }
    elsif ("$command" eq 'disable') {       # provide ability to disable xosd
        &info('xosd-notify disabled');
        $enabled = 0;
    }
    elsif ("$command" eq 'test') {          # print a test message to screen
                                            # useful for testing reconfigs
        $osd->string(0, 'xosd testing output');
    }
    elsif ("$command" eq 'reconfigure') {
        Irssi::signal_emit('setup changed');
        &osd_config();
        $osd->string(0, 'xosd-notify: reconfigured');
    }
    elsif ("$command" eq 'save') {
        &save_settings($args[0]);
    }
    else {                                  # default 'fall-through'
        &info('invalid command!');
    }
}

