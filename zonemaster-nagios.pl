#!/usr/bin/env perl

### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation, either version 3 of the License, or
### (at your option) any later version.

### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.

### You should have received a copy of the GNU General Public License
### along with this program.  If not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;

use Zonemaster;
use Zonemaster::Translator;
use Getopt::Long;
use Pod::Usage;

# global options
my $domain;
my $verbose = 0;
my $version;

# other globals
my $t = Zonemaster::Translator->new;
my $nagioscodes = {
    'DEBUG3'   => { 'string' => 'OK',       'code' => 0 },
    'DEBUG2'   => { 'string' => 'OK',       'code' => 0 },
    'DEBUG1'   => { 'string' => 'OK',       'code' => 0 },
    'DEBUG'    => { 'string' => 'OK',       'code' => 0 },
    'INFO'     => { 'string' => 'OK',       'code' => 0 },
    'NOTICE'   => { 'string' => 'OK',       'code' => 0 },
    'WARNING'  => { 'string' => 'WARNING',  'code' => 1 },
    'ERROR'    => { 'string' => 'CRITICAL', 'code' => 2 },
    'CRITICAL' => { 'string' => 'CRITICAL', 'code' => 2 },
};

## NOTE! On writing Nagios plugins - these have not all been implemented.
## There are a few reserved options that should not be used for other purposes:
##
## -V version (–version) ;
## -h help (–help) ;
## -t timeout (–timeout) ;
## -w warning threshold (–warning) ;
## -c critical threshold (–critical) ;
## -H hostname (–hostname) ;
## -v verbose (–verbose).

sub main {
    # non-global program parameters
    my $help = 0;
    my $name;
    GetOptions( 'help||h?'    => \$help,
	        'domain|d=s'  => \$domain,
		'verbose|v+'  => \$verbose,
		'version|V'   => \$version,
    ) or pod2usage( 2 );

    if ( defined $version ) {
	print "zonemaster-nagios.pl version 1.0.0\n";
	exit 3;
    }

    if ( not defined $domain ) {
	pod2usage( 2 );
	exit 2;
    }

    my @log = Zonemaster->test_zone( $domain );
    my $maxlevel = Zonemaster::logger->get_max_level();
    my $restext = $nagioscodes->{ $maxlevel }->{ 'string' };
    my $rescode = $nagioscodes->{ $maxlevel }->{ 'code' };
    my $resverbose; # the verbose text on the nagios status line
    my $d; # debug output
    foreach ( @{Zonemaster->logger->entries} ) {
	$d .= $t->to_string( $_ )."\n" if $_->level eq 'INFO'     and $verbose >= 3;
	$d .= $t->to_string( $_ )."\n" if $_->level eq 'NOTICE'   and $verbose >= 2;
	$d .= $t->to_string( $_ )."\n" if $_->level eq 'WARNING'  and $verbose >= 1;
	$d .= $t->to_string( $_ )."\n" if $_->level eq 'ERROR'    and $verbose >= 0;
	$d .= $t->to_string( $_ )."\n" if $_->level eq 'CRITICAL' and $verbose >= 0;
	if ( $_->level eq $maxlevel and not defined $restext ) {
	    $resverbose = " - ".$t->to_string( $_ );
	}
    }

    print "ZONE $restext";
    print $resverbose if defined $resverbose;
    print "\n";
    print $d if defined $d; # also print debug output
    exit $rescode;
}

main;

=head1 NAME

zonemager-nagios.pl

=head1 SYNOPSIS

   zonemaster-nagios.pl -d domain

   zonemaster-nagios.pl -v -v -d domain

=head1 DESCRIPTION

Nagios plugin using Zonemaster to report problems with a zone.

Increase verbosity by using the -v option.

=head1 AUTHOR

   Patrik Wallstrom <pawal@blipp.com>

=cut
