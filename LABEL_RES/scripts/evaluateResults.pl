#!/usr/bin/env perl

# Description:      Generates a shogun cmdline_static compatible script using
#                   input params. Outputs a revised result file using ID information.
#
# Date dedicated: 	2022-07-06
# Author: 			Samuel S. Shepard, Centers for Disease Control and Prevention
#
# Citation:         Shepard SS, Davis CT, Bahl J, Rivailler P, York IA, Donis
#                   RO. LABEL: fast and accurate lineage assignment with
#                   assessment of H5N1 and H9N2 influenza A hemagglutinins. PLoS
#                   One. 2014;9(1):e86921. Published 2014 Jan 23.
#                   doi:10.1371/journal.pone.0086921
#
# =============================================================================
#
#                            PUBLIC DOMAIN NOTICE
#
#  This source code file or script constitutes a work of the United States
#  Government and is not subject to domestic copyright protection under 17 USC §
#  105. This file is in the public domain within the United States, and
#  copyright and related rights in the work worldwide are waived through the CC0
#  1.0 Universal public domain dedication:
#  https://creativecommons.org/publicdomain/zero/1.0/
#
#  The material embodied in this software is provided to you "as-is" and without
#  warranty of any kind, express, implied or otherwise, including without
#  limitation, any warranty of fitness for a particular purpose. In no event
#  shall the Centers for Disease Control and Prevention (CDC) or the United
#  States (U.S.) government be liable to you or anyone else for any direct,
#  special, incidental, indirect or consequential damages of any kind, or any
#  damages whatsoever, including without limitation, loss of profit, loss of
#  use, savings or revenue, or the claims of third parties, whether or not CDC
#  or the U.S. government has been advised of the possibility of such loss,
#  however caused and on any theory of liability, arising out of or in
#  connection with the possession, use or performance of this software.
#
#  Please cite the manuscript  or author in any work or product based on this
#  material.

use strict;
use warnings;
use English qw(-no_match_vars);
use Getopt::Long;

my ( $terse, $header, $grouped, $suppress, $justSeqHeader, $pathList );
GetOptions(
            'terse|T'           => \$terse,
            'header|H'          => \$header,
            'grouped|G'         => \$grouped,
            'suppress|S'        => \$suppress,
            'just-seq-header|J' => \$justSeqHeader,
            'path-list|P=s'     => \$pathList
);

if ( scalar(@ARGV) != 1 ) {
    die(   "Usage:\n\tperl $PROGRAM_NAME <results.txt> [OPTIONS]\n"
         . "\t-G|--grouped\t\tResults were grouped using a hierarhical decimal scheme and prefix.\n"
         . "\t-H|--header\t\tData has a header row.\n"
         . "\t-S|--suppress\t\tSuppress printing of incorrect values.\n"
         . "\t-T|--terse\t\tSummary output is just number correct.\n"
         . "\t-J|--just-seq-header\tJust print STDOUT out sequence headers for incorrect values.\n"
         . "\t-P|--path-list\t\tUses a path list to evaluate correctness.\n"
         . "\n" );
}

my $IN;
open( $IN, '<', $ARGV[0] ) or die("Cannot open $ARGV[0].\n");
my ( $correct, $total ) = ( 0, 0 );
if ( defined($header) ) {
    $header = <$IN>;
}

my %pathArrayByAnnot = ();
if ( defined $pathList ) {
    my $PL;
    open( $PL, '<', $pathList ) or die("Cannot open path list $pathList for reading.\n");
    local $RS = "\n";
    while ( my $line = <PL> ) {
        chomp($line);
        my @pieces = split( '/', $line );
        my $annot  = pop(@pieces);
        my $junk   = shift(@pieces);
        if ( scalar @pieces > 1 ) {
            $junk = shift(@pieces);
            $pathArrayByAnnot{$annot} = [@pieces];
        }
    }
    close(PL) or croak("Cannot close $pathList");
    $pathList = 1;
} else {
    $pathList = 0;
}

# FNC - trim function.
# Removes whitespace from the start and end of the string
sub trim($) {
    my $string = shift;
    if ( $string =~ /^\s*(.*?)\s*$/smx ) {
        return $1;
    } else {
        return $string;
    }
}

my %annots    = ();
my %corByAnno = ();
while ( my $line = <$IN> ) {
    chomp($line);

    $total++;

    my @fields = split( /\t/smx, $line );
    $fields[0] = trim( $fields[0] );

    my $pred = trim( $fields[1] );
    my $anno = 'unknown';

    if ( $fields[0] =~ /{([^{}]*)}\s*$/sxm ) {
        $anno = $1;
    }

    if ( !defined $annots{$anno} ) { $annots{$anno} = 1; }
    else                           { $annots{$anno}++; }

    # Check annotation against prediction.
    if ( $anno eq $pred ) {
        if ( !defined( $corByAnno{$anno} ) ) { $corByAnno{$anno} = 1; }
        else                                 { $corByAnno{$anno}++; }
        $correct++;
        next;
    } elsif ( $grouped && $pred =~ /^c-(.+)$/smx ) {
        $pred = $1;
        if ( $anno =~ /^\Q$pred\E/smx ) {
            if ( !defined( $corByAnno{$anno} ) ) { $corByAnno{$anno} = 1; }
            else                                 { $corByAnno{$anno}++; }
            $correct++;
            next;
        }
    } elsif ($pathList) {
        if ( defined $pathArrayByAnnot{$anno} ) {
            my @alternatives = @{ $pathArrayByAnnot{$anno} };
            my $found        = 0;
            foreach my $alt (@alternatives) {
                if ( $pred eq $alt ) {
                    if ( !defined $corByAnno{$alt} ) { $corByAnno{$alt} = 1; }
                    else                             { $corByAnno{$alt}++; }

                    if ( !defined $annots{$alt} ) { $annots{$alt} = 1; }
                    else                          { $annots{$alt}++; }

                    if   ( $annots{$anno} == 1 ) { delete $annots{$anno} }
                    else                         { $annots{$anno}--; }

                    $correct++;
                    $found = 1;
                    last;
                }
            }

            if ($found) {
                next;
            }
        }
    }

    if ( !defined $suppress ) {
        if ($justSeqHeader) {
            print STDOUT $fields[0], "\n";
        } else {
            print STDOUT $line, "\n";
        }
    }
}
close($IN) or croak("Cannot close file: $ERRNO");

if ($pathList) {
    foreach my $anno ( keys(%annots) ) {
        if ( !defined $corByAnno{$anno} && defined $pathArrayByAnnot{$anno} ) {
            my @alternatives = @{ $pathArrayByAnnot{$anno} };
            foreach my $alt (@alternatives) {
                if ( defined $corByAnno{$alt} ) {
                    $annots{$alt} += $annots{$anno};
                    delete $annots{$anno};
                    last;
                }
            }
        }
    }
}

if ( defined($terse) ) {
    print STDOUT $correct, "\n";
} elsif ( !$justSeqHeader ) {
    print STDOUT '--------------------------------------', "\n";
    print STDOUT sprintf( "%10s\t%5s\t%5s\t%6s\n", 'CLADE', 'TP', 'Num', '%Acc' );
    print STDOUT '--------------------------------------', "\n";
    foreach my $anno ( sort { $a cmp $b } keys(%annots) ) {
        print sprintf( "%10s\t%5d\t%5d\t%5.1f%%\n",
                       $anno, $corByAnno{$anno}, $annots{$anno}, ( 100 * $corByAnno{$anno} / $annots{$anno} ) );
    }
    print STDOUT '--------------------------------------', "\n";
    print STDOUT sprintf( "%10s\t%5d\t%5d\t%5.1f%%\n", 'TOTAL', $correct, $total, ( 100 * $correct / $total ) );
    print STDOUT '--------------------------------------', "\n";
}

