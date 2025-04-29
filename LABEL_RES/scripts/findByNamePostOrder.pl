#!/usr/bin/env perl
# findByNamePostOrder - 2012
# Directory post-order traversal: outputs matching exact files by default.

use File::Basename;
use Getopt::Long;
GetOptions( 'contains|C' => \$contains, 'directory-only|D' => \$dirOnly, 'cat-print|P' => \$catPrint );

if ( scalar(@ARGV) != 2 && !defined($dirOnly) ) {
    $message = "Usage:\n\tperl $0 <base_directory> [<file/pattern> [-C]|-D]\n";
    $message .= "\t\t--contains|-C\t\tContains text in pattern.\n";
    $message .= "\t\t--directory-only|-D\tOnly process directories instead of file.\n";
    die($message);
}

$catPrint = defined($catPrint) ? 1 : 0;

sub cat($) {
    my $fh;
    if ( !defined( $_[0] ) || $_[0] eq "" ) { return; }
    open( $fh, '<', "$_[0]" ) or die("Cannot open $_[0] for reading.\n");
    while ( my $line = <$fh> ) {
        print $line;
    }
    close($fh);
    return 1;
}

#FNC - recursive post order traversal
sub postOrderByName($$$) {
    my $base  = $_[0];
    my $name  = $_[1];
    my $level = $_[2];

    my @contents = <"$base"/*>;
    my @files    = grep( -f $_, @contents );
    my @dirs     = grep( -d $_, @contents );
    my $file;
    my $dir;
    my $temp;

    # Traverse
    foreach $dir (@dirs) {
        &postOrderByName( $dir, $name, ( $level + 1 ) );
    }

    if ($dirOnly) {
        foreach $dir (@dirs) {
            print '"', $dir, "\"\n";
        }
        return;
    }

    if ($contains) {

        # Process
        foreach $file (@files) {
            if ( basename($file) =~ /$name/ ) {
                if ($catPrint) {
                    cat($file) or die("Can't cat $file: $!");
                } else {
                    if ( $level != 0 || $file ne $files[-1] ) {
                        print '"', $file, '" ';
                    } else {
                        print '"', $file, '"';
                    }
                }
            }
        }

    } else {

        # Process
        foreach $file (@files) {
            if ( basename($file) eq $name ) {
                if ($catPrint) {
                    cat($file) or die("Can't cat $file: $!");
                } else {
                    if ( $level != 0 || $file ne $files[-1] ) {
                        print '"', $file, '" ';
                    } else {
                        print '"', $file, '"';
                    }
                }
            }
        }
    }
}

my $base = $ARGV[0];
my $name = $ARGV[1];

postOrderByName( $base, $name, 0 );
####################
