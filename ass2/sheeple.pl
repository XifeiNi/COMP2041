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
		if ($shellLine =~ /^#[^!].*/) {
			push(@perlLines, $shellLine);
			next;
		}

		if ($shellLine =~ /\$(\d)/) {
                        my $arg = int($1) - 1;
                        $shellLine =~ s?\$(\d)?\$ARGV[$arg]?;
                }

		if ($shellLine =~ /\$\@/) {
			$shellLine =~ s?\$\@?\@ARGV?;
		}

		# start line
		if ($shellLine =~ /^#!.*/) {
			push(@perlLines, "#!/usr/bin/perl -w");
		} 

		# echo
		elsif ($shellLine =~ /echo (.*)/) {
			$shellLine =~ s?echo\s*['|"]{0,1}(.*)['|"]{0,1}?$1?;
			$shellLine =~ s?'??;		
			$shellLine =~ s?"$??;	
			$shellLine =~ s?"?\\"?g;
			push(@perlLines, $leadingSpaces.qq/print "$shellLine\\n";/);
		}

		# else
		elsif ($shellLine =~ /else/) {
			push(@perlLines, $leadingSpaces."} else {");
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
			my $assignLine = "";
			if (containDollar($2)) {
				my $newAss = evalLeftHandSide($2);
				$assignLine = qq/\$$1 = $newAss;/;
			} else {
				my $newAss = evalLeftHandSide($2);
				$assignLine = qq/\$$1 = '$newAss';/;
			} 
			push(@perlLines, $leadingSpaces.$assignLine);
		}

		# then
		elsif ($shellLine =~ /^then$/) {
			push(@perlLines, $leadingSpaces."{");
		}

		# curly bracket at the control block
		elsif ($shellLine =~ /^done$/
			or $shellLine =~ /^fi$/) {
			push(@perlLines, $leadingSpaces."}");
		}

		# loop statement -- for
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

		elsif ($shellLine =~ /^(\w+)\s+test\s+(\w+)\s*(\W+)\s*(\w+)/
			and !containSlash($shellLine)) {
			my $if = $1;
			if ($1 eq "elif") {
				$if = "} elsif";
			}
		
			my $operator = getOperator($3);
			push(@perlLines, $leadingSpaces.qq/$if ('$2'$operator'$4')/);
		}

		# while test $number -le $finish
		elsif ($shellLine =~ /^while\s+test\s+(\$\w+)\s*(-.+)\s*(\$\w+)/) {
			my $operator = getOperator($2);
			push(@perlLines, $leadingSpaces.qq/while ($1$operator$3) {/);
		}

		# if [ -d /dev/null ]
		elsif ($shellLine =~ /^(\w+)\s+\[\s+(-\w)\s+(.*)\s+\]/) {
			my $if = $1;
                        if ($1 eq "elif") {
                                $if = "} elsif";
                        }
			push(@perlLines, $leadingSpaces.qq/$if ($2 '$3')/);	
		}
		# if test -r /dev/null
		elsif ($shellLine =~ /^(\w+)\s+test\s+(-\w)\s+(.*)/ and containSlash($shellLine)) {
			my $if = $1;
                        if ($1 eq "elif") {
                                $if = "} elsif";
                        }
			push(@perlLines, $leadingSpaces.qq/$if ($2 '$3')/);
		}
	}	
	printPerlLines(@perlLines);
}

sub containSlash {
	my $string = $_[0];
	return $string =~ /-/;
}

sub containDollar {
	my $string = $_[0];
	return $string =~ /\$/;
}

sub evalLeftHandSide {
	my $string = $_[0];
	$string =~ s/`//g;
	$string =~ s/expr//;
	return $string;	
}

sub printPerlLines {
	foreach my $perl (@_) {
		print "$perl\n";
	}

}

sub getOperator {
	my $string = $_[0];
	my $operator = "";
	if ($string =~ /le/) {
		return " <= ";
	} elsif ($string =~ /lt/) {
		return " < ";
	} elsif ($string =~ /eq/) {
		return " == ";
	} elsif ($string =~ /ge/) {
		return " >= ";
	} elsif ($string =~ /gt/) {
		return " > ";
	}

	if ($string =~ /!=/) {
		$operator = " ne ";
	} else {
		$operator = " eq ";
	}
	return $operator;
	
}

sub getLeadingSpaces {
	my $string = $_[0];
	$string =~ /^(\s*)/;
	return $1;		
}
