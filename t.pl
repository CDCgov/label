

my $s = 'Sam/is/there';
foreach $x ( split(q{/},$s) ) {
    print $x,"\n";
}
