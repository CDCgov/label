#!/usr/bin/env perl
#
# rev - 2012
# Reverse complements the data.

use Getopt::Long;
GetOptions( 'fastQ|Q' => \$fastQ, 'reverse-only|R' => \$reverseOnly, 'single-line-mode|L' => \$singleLine );

if ( scalar(@ARGV) != 1 ) {
    die("Usage:\n\tperl $0 <input.fasta> [-Q] [-R] [-L]\n");
}

if ( defined($reverseOnly) ) {
    $takeComplement = 0;
} else {
    $takeComplement = 1;
}

if ($singleLine) {
    $sequence = $ARGV[0];
    $sequence = reverse($sequence);
    if ($takeComplement) {
        $sequence =~ tr/gcatrykmbvdhuGCATRYKMBVDHU/cgtayrmkvbhdaCGTAYRMKVBHDA/;
    }
    print $sequence, "\n";
    exit;
}

if ($fastQ) {
    $/ = "\n";
} else {
    $/ = ">";
}

while ( $record = <> ) {
    chomp($record);
    if ($fastQ) {
        $header   = $record;
        $sequence = <IN>;
        chomp($sequence);
        $junk = <IN>;
        chomp($junk);
        $quality = <IN>;
        chomp($quality);
        $quality = reverse($quality);
    } else {
        @lines    = split( /\r\n|\n|\r/, $record );
        $header   = shift(@lines);
        $sequence = lc( join( '', @lines ) );
    }

    $length = length($sequence);
    if ( $length == 0 ) {
        next;
    }
    $sequence = reverse($sequence);

    if ($takeComplement) {
        $sequence =~ tr/gcatrykmbvdhuGCATRYKMBVDHU/cgtayrmkvbhdaCGTAYRMKVBHDA/;
    }

    if ($fastQ) {
        print $header, "\n", $sequence, "\n", $junk, "\n", $quality, "\n";
    } else {
        print '>', $header, "\n", $sequence, "\n";
    }
}
