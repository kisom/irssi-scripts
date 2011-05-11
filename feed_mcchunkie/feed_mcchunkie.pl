#!/usr/bin/env perl
# feed_mcchunkie.pl
# author: 4096r/b7b720d6  "kyle isom <coder@kyleisom.net>"
# license: dual isc / public domain
# usage:
#   /load feed_mcchunkie


use warnings;
use strict;
use Data::Dumper;

use Irssi;
use vars qw($VERSION %IRSSI);

# set up script vars
$VERSION    = '0.1-alpha';
%IRSSI      = (
    authors             => 'kyle isom',
    origauthors         => 'kyle isom',
    contact             => 'coder@kyleisom.net',
    name                => 'feed_mcchunkie.pl',
    description         => 'every time mcchunkie talks or someone trains the ' .
                            'bot to say "no", will respond positively',
    license             => 'dual-licensed public domain / ISC',
    url                 => 'http://www.brokenlcd.net/code/irssi/index.html',
);

my $bot_nick   = 'mcchunkie';

### start ###
&init();


# thanks brycec
sub mensaje {
    my ($cmd, $server, $winitem) = @_;
    my ( $param, $target, $data) = $cmd =~ /^(-\S*\s)?(\S*)\s(.*)/;
    
    Irssi::print("target: $target");
    Irssi::print("data:   $data");

}

sub window_test {
    for my $item (@_) { print $item; }
    my ($server, $chan, $nick, $address) = @_;
    #my ($channel, $blah) = @_;
    Irssi::print("$chan");
    
    if ($chan =~ /^$bot_nick: no/) {
        Irssi::print('sending counter message!' . " '$bot_nick: yes'");
        $server->send_message($chan, "$bot_nick: yes", 0);
        $server->print($chan, 'tesitng');
    }
}

sub init {
    #Irssi::signal_add_last('message public', 'chan_msg');
    #Irssi::signal_add('server sendmsg', 'window_test');
    #Irssi::signal_add('msg', 'chan_msg');
    Irssi::signal_add('message public', 'window_test');
    #Irssi::signal_add("window activity", 'window_test');
}