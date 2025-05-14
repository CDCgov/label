#!/usr/bin/env perl
# removeGapColumns.pl - 2012
# Removes gap columns (100% gaps) from FASTA alignments.
# Warning, this program overwrites the source file.

use Getopt::Long;
GetOptions( 'display-k-tons|D=i' => \$ktons, 'remove-k-tons|R' => \$removeKtons );

if ( scalar(@ARGV) != 1 ) {
    $message = "Usage:\n\tperl $0 <file.fasta> [options]\n";
    $message .= "\t\t-D|-display-k-tons\tDisplays sequences where for columns with 0 < bases <= K.\n";
    die($message);

}

open( IN, '<', $ARGV[0] ) or die("Cannot open $ARGV[0].\n");

# PROCESS fasta data
$/ = ">";
$i = 0;
while ( $record = <IN> ) {
    chomp($record);
    @lines        = split( /\r\n|\n|\r/, $record );
    $header[$i]   = shift(@lines);
    $sequence[$i] = join( '', @lines );
    $length       = length( $sequence[$i] );

    if ( $length == 0 ) {
        next;
    }

    # unify gap characters
    $sequence[$i] =~ tr/:~./-/;

    $R = index( $sequence[$i], '-', 0 );
    while ( $R != -1 ) {
        $gaps{$R}++;
        $R = index( $sequence[$i], '-', $R + 1 );
    }
    $i++;
}
close(IN);
$numSeqs = $i;

if ( $ktons > 0 ) {

    # Find and display sequences associated with k-ton support for each column.
    %ktons  = ();
    @sorted = sort { $a <=> $b } ( keys(%gaps) );
    foreach $g (@sorted) {
        $support = $numSeqs - $gaps{$g};
        if ( $support <= $ktons ) {
            print "$g:$support\n";
            $i = 0;
            while ( $support > 0 && $i < $numSeqs ) {
                $base = substr( $sequence[$i], $g, 1 );
                if ( '-' ne $base ) {
                    print "\t", uc($base), " ", $header[$i], "\n";
                    $support--;
                }
                $i++;
            }
            delete( $gaps{$g} );
        }
    }

    if ( defined($removeKtons) ) {

        # Update file using an overwrite
        open( OUT, '>', $ARGV[0] ) or die("Cannot open $ARGV[0] for writing.\n");
        @sorted = sort { $b <=> $a } ( keys(%gaps) );
        for ( $i = 0; $i < $numSeqs; $i++ ) {
            foreach $R (@sorted) {
                substr( $sequence[$i], $R, 1, '' );
            }
            print OUT '>', $header[$i], "\n", $sequence[$i], "\n";
        }
        close(OUT);
    }
} else {

    # Find 100% gap columns
    foreach $g ( keys(%gaps) ) {
        if ( $gaps{$g} != $numSeqs ) {
            delete( $gaps{$g} );
        }
    }

    # Update file using an overwrite
    open( OUT, '>', $ARGV[0] ) or die("Cannot open $ARGV[0] for writing.\n");
    @sorted = sort { $b <=> $a } ( keys(%gaps) );
    for ( $i = 0; $i < $numSeqs; $i++ ) {
        foreach $R (@sorted) {
            substr( $sequence[$i], $R, 1, '' );
        }
        print OUT '>', $header[$i], "\n", $sequence[$i], "\n";
    }
    close(OUT);
}
