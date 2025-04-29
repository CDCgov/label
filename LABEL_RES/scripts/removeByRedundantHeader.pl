#!/usr/bin/env perl
# removeByRedundantHeader - 2012
# Remove sequences from a FASTA given the header is entirely redundant.

use Getopt::Long;
GetOptions( 'underline-spaces|U' => \$underline );

if ( -t STDIN and not @ARGV ) {
    die("Usage:\n\tperl $0 <file.fa> [-U]\n");
}

# PROCESS fasta data
$/       = ">";
%headers = ();
while ( $record = <> ) {
    chomp($record);
    @lines    = split( /\n/, $record );
    $header   = shift(@lines);
    $sequence = lc( join( '', @lines ) );
    if ($underline) { $header =~ tr/ /_/d; }

    if ( length($sequence) == 0 ) {
        next;
    } elsif ( !exists( $headers{$header} ) ) {
        $headers{$header} = $sequence;
    }
}

# OUTPUT non-redundant from the hash
foreach $header ( keys(%headers) ) {
    print '>', $header, "\n";
    print $headers{$header}, "\n";
}
####################
