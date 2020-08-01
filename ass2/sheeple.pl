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
		my $leadingSpaces = getLeadingSpaces($shellLine);
		$shellLine=~s/^\s*//;
		chomp $shellLine;
		# start line
		if ($shellLine =~ /^#!.*/) {
			push(@perlLines, "#!/usr/bin/perl -w");
		} 
		# echo
		elsif ($shellLine =~ /echo (.*)/) {
			$shellLine =~ s?echo (.*)?print "$1\\n";?;
			push(@perlLines, $leadingSpaces.$shellLine);
		} 
		# system functions
		elsif ($shellLine =~ /cd (.*)/ 
			or $shellLine =~ /pwd/ 
			or $shellLine =~ /id/ 
			or $shellLine =~ /date/ 
			or $shellLine =~ /ls/
			or $shellLine =~ /ls (.*)/ ) {
			my $sysLine = qq/system "$shellLine";/;
			push(@perlLines, $leadingSpaces.$sysLine);
		}
		# variable assignment
		elsif ($shellLine =~ /^(\w+)\s*=\s*(.*)$/) {
			my $assignLine = qq/\$$1 = '$2';/;
			push(@perlLines, $leadingSpaces.$assignLine);
		}
		# curly bracket at the end of loop
		elsif ($shellLine =~ /done/) {
			push(@perlLines, $leadingSpaces."}");
		}
		# loop statement
		elsif ($shellLine =~ /^for (.*) in (.*)/) {
			@array =  split(" ", $2);
			my $loopString = "";
			if (scalar @array == 1) {
				$loopString = qq/(glob("$2"))/;
			} else {
				@newArray = ();
				foreach $element (@array) {
					push(@newArray, qq/'$element'/);
				}
				$loopString = '('.join(' , ', @newArray).')';
			}
			my $forString = qq/foreach \$$1 $loopString {/;
			push(@perlLines, $leadingSpaces.$forString);
		}
		elsif ($shellLine =~ /exit (.*)/) {
			push(@perlLines, $leadingSpaces.$shellLine);			
		}
		# read line
		elsif ($shellLine =~ /read (.*)/) {
			push(@perlLines, $leadingSpaces."\$$1 = <STDIN>;");
			push(@perlLines, $leadingSpaces."chomp \$$1;");
		}
	}	
	printPerlLines(@perlLines);
}

sub printPerlLines {
	foreach my $perl (@_) {
		print "$perl\n";
	}

}

sub getLeadingSpaces {
	my $string = $_[0];
	$string =~ /^(\s*)/;
	return $1;		
}
