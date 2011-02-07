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
my $osd             = "";

sub init {
    # set up Irssi settings
    Irssi::settings_add_str('xosd-notify', 'xosd_font', 'fixed');
    Irssi::settings_add_str('xosd-notify', 'xosd_foreground', '#00FF00');
    Irssi::settings_add_str('xosd-notify', 'xosd_background', '#000000');
    Irssi::settings_add_str('xosd-notify', 'xosd_shadow-colour', '#111');
    Irssi::settings_add_str('xosd-notify', 'xosd_position', 'top-left');
    Irssi::settings_add_int('xosd-notify', 'xosd_timeout', 5);
    Irssi::settings_add_int('xosd-notify', 'xosd_border', 10); 

    # set up Irssi signal handlers
    Irssi::signal_add_last('event privmsg', 'event_privmsg');
    Irssi::signal_add_last('window hilight', 'win_hl');

    $osd = X::Osd->new($num_lines); 
    &osd_setup();

}

sub osd_setup {
    my ($vert, $horiz) = &translate_position(Irssi::settings_get_str(
        'xosd_position'));

    $osd->set_font(Irssi::settings_get_str('xosd_font'));
    $osd->set_colour(Irssi::settings_get_str('xosd_foreground'));
    $osd->set_outline_color(Irssi::settings_get_str('xosd_background'));
    $osd->set_outline_offset(Irssi::settings_get_int('xosd_border'));
    $osd->set_pos($vert);
    $osd->set_align($horiz);
    $osd->set_timeout(Irssi::settings_get_int('xosd_timeout'));

    # should add option to use shadow and offset sizes
    # $osd->set_horizontal_offset()
    # $osd->set_vertical_offset();
    # $osd->set_shadow_offset();
    # $osd->set_shadow_colour();

    # osd should be done
    $osd->string(0, "xosd-notify $VERSION loaded!");

}

sub translate_position {
    my ($position)  = @_ ;
    my $vert        = '';
    my $horiz       = '';

    $position = lc($position);

    # get vertical position
    if    ( $position =~ /^top/ )       { $vert = XOSD_top; }
    elsif ( $position =~ /^middle/ )    { $vert = XOSD_middle; }
    elsif ( $position =~ /^center/ )    { $vert = XOSD_middle; }
    elsif ( $position =~ /^bottom/ )    { $vert = XOSD_bottom; }
    else                                { $vert = XOSD_top; }       # default

    # get horizontal position
    if    ( $position =~ /right$/ )     { $horiz = XOSD_right; }
    elsif ( $position =~ /left$/ )      { $horiz = XOSD_left; }
    elsif ( $position =~ /center$/ )    { $horiz = XOSD_center; }
    elsif ( $position =~ /middle$/ )    { $horiz = XOSD_center; }
    else                                { $horiz = XOSD_left; }     # default

    return ($vert, $horiz);
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_ ;
    $osd->string("data: $data");
    sleep 2;
    Irssi::print("data: $data");
}

sub win_hl {
    Irssi::print("window hilight triggered", Irssi::MSGLEVEL_CLIENTNOTICE);

}
