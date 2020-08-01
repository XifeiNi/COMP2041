#!/usr/bin/perl -w

if ($#ARGV < 0) {
	my @standIn = <STDIN>;
	shellToPerl(@standIn);
} else {
	open SHELL, "<$ARGV[0]" or die "Can't open file $ARGV[0]";
	my @shellFile = <SHELL>;
	shellToPerl(@shellFile);
}

sub shellToPerl {
	@perlLines = ();
	foreach my $shellLine (@_) {
		$shellLine=~s/^\s*//;
		chomp $shellLine;
		# start line
		if ($shellLine =~ /^#!.*/) {
			push(@perlLines, "#!/usr/bin/perl -w");
		} 
		# echo
		elsif ($shellLine =~ /echo (.*)/) {
			$shellLine =~ s?echo (.*)?print "$1\\n";?;
			push(@perlLines, $shellLine);
		} 
		# system functions
		elsif ($shellLine =~ /cd (.*)/ 
			or $shellLine =~ /pwd/ 
			or $shellLine =~ /id/ 
			or $shellLine =~ /date/ 
			or $shellLine =~ /ls/
			or $shellLine =~ /ls (.*)/ ) {
			my $sysLine = qq/system "$shellLine";/;
			push(@perlLines, $sysLine);
		}
		# variable assignment
		elsif ($shellLine =~ /^(\w+)\s*=\s*(.*)$/) {
			my $assignLine = qq/\$$1 = '$2';/;
			push(@perlLines, $assignLine);
		}
	}	
	printPerlLines(@perlLines);
}

sub printPerlLines {
	foreach my $perl (@_) {
		print "$perl\n";
	}

}
