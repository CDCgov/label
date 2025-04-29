#!/usr/bin/env perl
# parseScores - 2012
# Converts SAM score distance files to a tab-delimited format.

if ( scalar(@ARGV) < 1 ) {
    die("Usage:\n\tperl $0 <scores.dist ...>\n");
}
$/       = "\n";
@headers = @fields = ();
while ( $line = <> ) {
    chomp($line);
    if ( $line =~ m/^% Sequence ID/ ) {
        $line =~ tr/%//d;
        $line    = trim($line);
        @headers = split( /\s{2,}/, $line );
        print $headers[0], "\t", $headers[1], "\t", $headers[2], "\t", $headers[3], "\n";
        last;
    } elsif ( $line !~ m/^%/ ) {
        @fields = split( /\s+/, $line );
        print $fields[0], "\t", $fields[1], "\t", $fields[2], "\t", $fields[3], "\n";
    }
}

while ( $line = <> ) {
    chomp($line);
    if ( $line !~ m/^%/ ) {
        @fields = split( /\s+/, $line );
        print $fields[0], "\t", $fields[1], "\t", $fields[2], "\t", $fields[3], "\n";
    }
}

# FNC - Trim function.
# Removes whitespace from the start and end of the string
sub trim($) {
    my $string = shift;
    $string =~ /^\s*(.*?)\s*$/;
    return $1;
}
####################
