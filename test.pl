#!/usr/bin/env perl

use strict;
use warnings;

use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION='0.0.1';
%IRSSI = (
    authors     => 'kyle isom',
    origauthors => 'kyle isom',
    contact     => 'coder@kyleisom.net',
    name        => 'test.pl',
    description => 'test script to verify Perl::Irssi is loaded',
    license     => 'dual licensed public domain / ISC',
    url         => 'NULL',
);

Irssi::print('[+] test.pl: Irssi module loaded successfully!');


