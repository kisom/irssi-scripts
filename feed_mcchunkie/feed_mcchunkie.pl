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


#  stupid simple
sub window_test {
    my ($server, $message, $nick, $address, $chan) = @_;
    
    if ($message=~ m/^$bot_nick: no/) {
        $server->send_message($chan, "$bot_nick: yes", 0);
    }
}

sub init {
    Irssi::signal_add('message public', 'window_test');
}