#!/usr/bin/env perl
# finalizeResults - 2012
# Modifies FASTA headers & creates txt/tab data for LABEL's recursive results.

if ( scalar(@ARGV) != 3 ) {
    die("Usage:\n\tperl $0 <input.tab> <input.fasta> <output_prefix>\n");
}

open( OUT, '>', $ARGV[2] . '_final.txt' ) or die("$0 ERROR: Cannot open $ARGV[2]_final.txt\n");
open( TAB, '>', $ARGV[2] . '_final.tab' ) or die("$0 ERROR: Cannot open $ARGV[2]_final.tab\n");

%results = ();
open( IN, '<', $ARGV[0] ) or die("$0 ERROR: Cannot open $ARGV[0]/\n");
while ( $line = <IN> ) {
    chomp($line);
    @fields = split( "\t", $line );
    if ( !defined( $results{ $fields[0] } ) ) {
        $results{ $fields[0] } = $fields[1];
    }
}
close(IN);

# PRINT data sorted by clade
@sorted = sort { $results{$a} cmp $results{$b} } ( keys(%results) );
print OUT sprintf( "%80s\t%20s\n", 'VIRUS STRAIN', 'CLADE' );
foreach $id (@sorted) {
    $lineage = $results{$id};
    print OUT sprintf( "%80s\t%20s\n", $id, $lineage );
    print TAB $id, "\t", $lineage, "\n";
}
close(OUT);

# PRINT a FASTA with adjusted headers
$i     = 1;
$delim = "_";
$/     = ">";
open( SEQ, '<', $ARGV[$i] )            or die("$0 ERROR: Cannot open $ARGV[$i].\n");
open( OUT, '>', $ARGV[$i] . '.final' ) or die("$0 ERROR: Cannot open $ARGV[$i].predictions\n");
while ( $record = <SEQ> ) {
    chomp($record);
    @lines    = split( /\r\n|\n|\r/, $record );
    $id       = $header = shift(@lines);
    $sequence = join( '', @lines );

    if ( length($sequence) == 0 ) {
        next;
    }

    $header .= $delim . '{PRED:' . $results{$id} . '}';
    print OUT '>', $header, "\n", $sequence, "\n";
}
close(SEQ);
close(OUT);
####################
