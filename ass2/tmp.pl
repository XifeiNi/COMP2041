#!/usr/bin/perl -w
$start = 13;
if (@ARGV > 0) {
    $start = $ARGV[0];
}
$i = 0;
$number = $start;
$file = './tmp.numbers';
system "rm -f $file";
while (1) {
	if (-r '$file') {
		print "Terminating because series is repeating\n";
	}
	print "$i $number\n";
    	$k =  $number % 2;
    	if ($k == 1) {
        	$number =  7 * $number + 3;
    	} else {
        	$number =  $number / 2;
    	}
	$i =  $i + 1;
}
