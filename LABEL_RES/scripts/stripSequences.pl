#!/usr/bin/env perl
# stripSequences - 2012
# Strips unwanted chracters from the fasta sequence (such as alignment characters).
# May also "fix" the header via trimming, underlining spaces & removing commas/apostrophes.

use Getopt::Long;
GetOptions( 'fix-header|F' => \$fixHeader, 'strip-lower|L' => \$stripLower );
if ( ( defined($stripLower) && scalar(@ARGV) != 1 ) || ( !defined($stripLower) && scalar(@ARGV) != 2 ) ) {
    die("Usage:\n\t$0 [-F] <file.fas> {-L|<quoted_characters_to_delete>}\n");
}

open( IN, '<', $ARGV[0] ) or die("$0 ERROR: Cannot open $ARGV[0].\n");

# PREPARE the strip deletion
$strip = '$sequence =~ tr/' . $ARGV[1] . '//d;';

# PROCESS fasta data
$/ = ">";
while ( $record = <IN> ) {
    chomp($record);
    @lines  = split( /\r\n|\n|\r/, $record );
    $header = shift(@lines);
    if ($fixHeader) {
        $header =~ s/^\s*(.*?)\s*$/\1/;
        $header =~ s/[\s:]/_/g;
        $header =~ tr/',//d;
    }
    $sequence = join( '', @lines );
    if ($stripLower) {
        $sequence =~ tr/[a-z]//d;
    } else {
        eval($strip);
    }

    if ( length($sequence) == 0 ) {
        next;
    } else {
        print '>', $header, "\n";
        print $sequence, "\n";
    }
}
close(IN);
####################
