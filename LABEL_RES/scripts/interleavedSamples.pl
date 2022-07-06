#!/usr/bin/env perl
#
# Description: 		Interleaved sampling of a FASTA file.
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


use File::Basename;
use Getopt::Long;
GetOptions(	'groups|G=i'=> \$numberGroups,
		    'fraction|F=i' => \$fraction,
		    'fastQ|Q' => \$fastQ,
		    'by-read-pairs|P' => \$byReadPairs,
		    'read-zipped|Z' => \$readZipped,
		    'underscore-header|U' => \$underscoreHeader,
       		'extension|X:s' => \$extension	
);

if (  scalar(@ARGV) < 2 ) {
	$message = "\n$0 <input.fasta> <out_prefix> [-G <#groups>|-F <denom-fraction>] [OPTIONS]\n";
	$message .= "\t-F|--fraction POSITIVE_NUMBER\t\tFraction of dataset, using denominator D: 1/D.\n";
	$message .= "\t-G|--groups POSITIVE_NUMBER\t\tNumber of datasets required.\n";
	$message .= "\t-X|--extension\t\t\t\tExtension for output samplings.\n";
	$message .= "\t-Q|--fastQ\t\t\t\tFastQ format for input and output.\n";
	$message .= "\t-P|--by-read-pairs\t\t\tFastQ format for IN/OUT, interleave by read molecular ID (implies -Q).\n";
	die($message."\n");
}
$PROGRAM = basename($0,'.pl');

if ( $byReadPairs ) {
	$fastQ = 1;
}

if ( $fastQ ) {
	$extension = 'fastq';
}

if ( defined($fraction) && defined($numberGroups) ) {
	die("$PROGRAM ERROR: specify Fraction OR the number of Groups.\n");
} elsif ( defined($numberGroups) ) {
	if ( $numberGroups < 1 ) {
		die("ERROR: The number of groups must be more than zero.\n");
	} elsif( $numberGroups > 9999 ) {
		print STDERR "$PROGRAM WARNING: groups currently capped to 9999.\n";
		$numberGroups = 9999;
	}
	$fraction = 0;
} else {
	$numberGroups = $fraction;
	if ( $numberGroups < 2 ) {
		die("$PROGRAM ERROR: The denominator must be more than one.\n");
	}
	$fraction = 1;
}

if ( $fraction ) {
	if ( $numberGroups =~ /1$/ ) {
		$suffix = 'st';
	} elsif ( $numberGroups =~ /2$/ ) {
		$suffix = 'nd';
	} elsif ( $numberGroups =~ /3$/ ) {
		$suffix = 'rd';
	} else {
		$suffix = 'th';
	}

	$filename = sprintf("%s_%d%s",$ARGV[1],$numberGroups,$suffix);
	if ( defined($extension) ) {
		$filename .= '.'.$extension; 
	} else {
		$filename .= '.fasta';
	}
	open($handle, '>', $filename ) or die("$PROGRAM ERROR: cannot open $filename\n");
} else {
	@handles = @count = ();
	for($i = 0;$i < $numberGroups; $i++ ) {
		$filename = sprintf("%s_%04d",$ARGV[1],($i+1));
		if ( defined($extension) ) {
			$filename .= '.'.$extension; 
		} else {
			$filename .= '.fasta';
		}
		open( $handles[$i], '>', $filename ) or die("$PROGRAM ERROR: Cannot open $filename\n");
		$files[$i] = $filename;
		$count[$i] = 0;
	}
}

# process parameters
chomp(@ARGV);
if ( $readZipped ) {
	open( IN, "zcat $ARGV[0] |" ) or die("$PROGRAM ERROR: Could not open $ARGV[0].\n");
} else {
	open( IN, '<', $ARGV[0] ) or die("$PROGRAM ERROR: Could not open $ARGV[0].\n");
}
$id = 0;
if ( $fastQ ) {
	$/ = "\n"; 
	if ( $byReadPairs ) {
		%indexByMolID = ();
		$REgetMolID = qr/@(.+?)[_ ][123]:.+/;
		while($hdr=<IN>) {
			$seq=<IN>;
			$junk=<IN>;
			$quality=<IN>; chomp($quality);
			if ( $hdr =~ $REgetMolID ) {
				$molID = $1;
				if ( defined($indexByMolID{$molID}) ) {
					$index = $indexByMolID{$molID};
				} else {
					$index = $id % $numberGroups;
					$indexByMolID{$molID} = $index;
					$id++;
					$count[$index]++;
				}
			} else {
				die("Irregular header for fastQ read pairs.\n");
			}
						
			if ( !$fraction ) {
				$handle = $handles[$index];
				print $handle $hdr,$seq,$junk,$quality,"\n";
			} elsif( $index == 0 ) {
				print $handle $hdr,$seq,$junk,$quality,"\n";
			}
		}
	} else {
		while($hdr=<IN>) {
			$seq=<IN>;
			$junk=<IN>;
			$quality=<IN>; chomp($quality);

			$index = $id % $numberGroups;
			$id++;
			$count[$index]++;
			if ( !$fraction ) {
				$handle = $handles[$index];
				print $handle $hdr,$seq,$junk,$quality,"\n";
			} elsif( $index == 0 ) {
				print $handle $hdr,$seq,$junk,$quality,"\n";
			}
		}
	}
} else {
	$/ = ">";
	while( $record = <IN> ) {
		chomp($record);
		@lines = split(/\r\n|\n|\r/, $record);
		$header = shift(@lines);
		if ( defined($underscoreHeader) ) { $header =~ tr/ /_/; }
		$sequence = lc(join('',@lines));

		$length = length($sequence);
		if ( $length == 0 ) {
			next;	
		}

		$index = $id % $numberGroups;
		$id++;
		$count[$index]++;
		if ( !$fraction ) {
			$handle = $handles[$index];
			print $handle '>',$header,"\n",$sequence,"\n";
		} elsif( $index == 0 ) {
			print $handle '>',$header,"\n",$sequence,"\n";
		}
	}
}
close(IN);
if ( $fraction ) {
	close($handle);
	print "\n Total\t  Got\tSample Name\n";
	print '----------------------------------------------------',"\n";
	printf("%6d\t%5d\t%s\n",$id,$count[0],$filename);
	print '----------------------------------------------------',"\n";
} else {
	foreach $handle (@handles) {
		close($handle);
	}
	print "\n Total\t  Got\tSample Name\n";
	print '----------------------------------------------------',"\n";
	for($i = 0;$i < $numberGroups;$i++) {
		printf("%6d\t%5d\t%s\n",$id,$count[$i],$files[$i]);
	}
	print '----------------------------------------------------',"\n";
}


