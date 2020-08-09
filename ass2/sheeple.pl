#!/usr/bin/perl -w

if ($#ARGV < 0) {
	my @standIn = <STDIN>;
	shellToPerl(@standIn);
} else {
	open SHELL, "<$ARGV[0]" or die "Can't open file $ARGV[0]";
	my @shellFile = <SHELL>;
	shellToPerl(@shellFile);
}

sub preProcess {
	my $shellLine = $_[0];
	my $leadingSpaces = getLeadingSpaces($shellLine);
	$shellLine=~s/^\s*//;
	chomp $shellLine;
	if (not $inFunctionScope) {
		$shellLine =~ s?"\$@"?\@ARGV?;
		$shellLine =~ s?"\$\#"?\@ARGV?;
		$shellLine =~ s?\$@?\@ARGV?;
		$shellLine =~ s?\$#?\@ARGV?;
	}
	
	# comments
	if ($shellLine =~ /#([^!].*)/) {
		push(@perlLines, qq\$leadingSpaces#$1\);
		$shellLine =~ s/$1//;
		$shellLine =~ s/#//;
		$shellLine =~ s/\s+//g;
	}

	# replace arg
	if ($shellLine =~ /\$(\d)/) {
                my $arg = int($1) - 1;
		if ($inFunctionScope) {
 	                $shellLine =~ s?\$(\d)?\$_[$arg]?;
		} else {
                        $shellLine =~ s?\$(\d)?\$ARGV[$arg]?;
		}
        }
	return $shellLine;
}

sub containAnd {
	my $string = $_[0];
	my @shells = split('&&', $string);
	my $retVal = "";
	foreach $shell (@shells) {
		
	} 	
}

my $inFunctionScope = 0;
sub shellToPerl {
	@perlLines = ();
	foreach my $shellLine (@_) {
		my $leadingSpaces = getLeadingSpaces($shellLine);
		
		# comment
		if ($shellLine =~ /^\s*#[^!].*/) {
			push(@perlLines, $leadingSpaces.$shellLine);
			next;
		}
		
		my $temp = $shellLine;
		$shellLine = preProcess($temp);
	
		# start line
		if ($shellLine =~ /^#!.*/) {
			push(@perlLines, "#!/usr/bin/perl -w");
		} 

		# contains &&
		elsif ($shellLine =~ /&&/) {
			my $temp = $shellLine;
			$shellLine = containAnd($temp);
			push(@perlLines, $leadingSpaces.$shellLine);
		}

		# echo
		elsif ($shellLine =~ /echo (.*)/) {
			# handle -n flag.
			if (containSlash($shellLine)) {
				my $temp = $shellLine;
				$shellLine = removeTrailingNewLine($temp);	
			}

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
		elsif ($shellLine =~ /^cd (.*)/ 
			or $shellLine =~ /^pwd/ 
			or $shellLine =~ /^id/ 
			or $shellLine =~ /^date/
			or $shellLine =~ /^chmod/
			or $shellLine =~ /^mv/ 
			or $shellLine =~ /^ls/
			or $shellLine =~ /^rm/
			or $shellLine =~ /^ls (.*)/ ) {
			my $sysLine = qq/system "$shellLine";/;
			push(@perlLines, $leadingSpaces.$sysLine);
		}

		# variable assignment outside of function
		elsif ($shellLine =~ /^(\w+)\s*=\s*(.*)$/) {
			my $assignLine = "";
			if (containDollar($2) or pureNumeric($2)) {
				my $newAss = evalLeftHandSide($2);
				$assignLine = qq/\$$1 = $newAss;/;
			} else {
				my $newAss = evalLeftHandSide($2);
				$assignLine = qq/\$$1 = '$newAss';/;
			} 
			push(@perlLines, $leadingSpaces.$assignLine);
		}
		
		#variable assignment inside of function (e.g) local n i
		elsif ($shellLine =~ /local/) {
			my @variables =  split / /,$shellLine;
			my $start = 1;
			my $assign = "my (";
			while ($start < scalar @variables) {
				if ($start == 1) {
					$assign = $assign."\$".$variables[$start];
				} else {
					$assign = $assign.", \$".$variables[$start];
				}
				$start = $start + 1;
			}
			$assign = $assign.");";
			push(@perlLines, $leadingSpaces.$assign);
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

		# exit
		elsif ($shellLine =~ /exit (.*)/) {
			push(@perlLines, $leadingSpaces.$shellLine.";");	
		}

		# return
		elsif ($shellLine =~ /return (.*)/) {
			push(@perlLines, $leadingSpaces.$shellLine.";");			
		}

		# start of function block
		elsif ($shellLine =~ /(\w+)\(\)\s*{/) {
			$inFunctionScope = 1;
			push(@perlLines, $leadingSpaces."sub ".$1." {");
		}  

		# end of function block
		elsif ($shellLine =~ /\s*}$/) {
			$inFunctionScope = 0;
			push(@perlLines, $leadingSpaces."}");
		}

		# read line
		elsif ($shellLine =~ /read (.*)/) {
			push(@perlLines, $leadingSpaces."\$$1 = <STDIN>;");
			push(@perlLines, $leadingSpaces."chomp \$$1;");
		}

		# string condition
		elsif ($shellLine =~ /^(\w+)\s+test\s+(\w+)\s*(\W+)\s*(\w+)/
			and !containSlash($shellLine)) {
			my $if = $1;
			if ($1 eq "elif") {
				$if = "} elsif";
			}
		
			my $operator = getOperator($3);
			push(@perlLines, $leadingSpaces.qq/$if ('$2'$operator'$4') {/);
		}

		elsif ($shellLine =~ /^(\w+)\s+test\s+(\$\w+)\s*(-.*)\s*(\$\w+)/) {
			my $operator = getOperator($3);
			my $if = $1;
			if ($1 eq "elif") {
				$if = "} elsif";
			}
			push(@perlLines, $leadingSpaces.qq/$if ($2$operator$4) {/);
		
		}

		elsif ($shellLine =~ /^(\w+)\s+test\s+(@\w+)\s*(-.*)\s*(\$\w+)/) {
			my $operator = getOperator($3);
			my $if = $1;
			if ($1 eq "elif") {
				$if = "} elsif";
			}
			push(@perlLines, $leadingSpaces.qq/$if ($2$operator$4) {/);
		
		}

		elsif ($shellLine =~ /^(\w+)\s+test\s+(@\w+)\s*(-.*)\s*([0-9]+)/) {
			my $operator = getOperator($3);
			my $if = $1;
			if ($1 eq "elif") {
				$if = "} elsif";
			}
			push(@perlLines, $leadingSpaces.qq/$if ($2$operator$4) {/);
		
		}

		elsif ($shellLine =~ /^(\w+)\s+test\s+(\$\w+)\s*(-.*)\s*([0-9]+)/) {
			my $operator = getOperator($3);
			my $if = $1;
			if ($1 eq "elif") {
				$if = "} elsif";
			}
			push(@perlLines, $leadingSpaces.qq/$if ($2$operator$4) {/);
		}

		# while test $number -le $finish
		elsif ($shellLine =~ /^while\s+test\s+(\$\w+)\s*(-.+)\s*(\$\w+)/) {
			my $operator = getOperator($2);
			push(@perlLines, $leadingSpaces.qq/while ($1$operator$3) {/);
		}

		elsif ($shellLine =~ /^while\s+test\s+(\$\w+)\s*(-\w+)\s*([0-9]+)/) {
			my $operator = getOperator($2);
			push(@perlLines, $leadingSpaces.qq/while ($1$operator$3) {/);
		}

		elsif ($shellLine =~ /^while\s+true/) {
			push(@perlLines, $leadingSpaces.qq/while (1) {/);
		}

		# if [ -d /dev/null ]
		elsif ($shellLine =~ /^(\w+)\s+\[\s+(-\w)\s+(.*)\s+\]/) {
			my $if = $1;
                        if ($1 eq "elif") {
                                $if = "} elsif";
                        }
			push(@perlLines, $leadingSpaces.qq/$if ($2 '$3') {/);	
		}
		# if test -r /dev/null
		elsif ($shellLine =~ /^(\w+)\s+test\s+(-\w)\s+(.*)/ and containSlash($shellLine)) {
			my $if = $1;
                        if ($1 eq "elif") {
                                $if = "} elsif";
                        }
			push(@perlLines, $leadingSpaces.qq/$if ($2 '$3') {/);
		}
	}	
	printPerlLines(@perlLines);
}

sub removeTrailingNewLine {
	my $string = $_[0];
	$string =~ s/\R//g;
	return $string;
}

sub containSlash {
	my $string = $_[0];
	return $string =~ /-/;
}

sub pureNumeric {
	my $string = $_[0];
	return $string =~ /\s*[0-9]+\s*/;
}

sub containDollar {
	my $string = $_[0];
	return $string =~ /\$/;
}

sub evalLeftHandSide {
	my $string = $_[0];
	$string =~ s/`//g;
	$string =~ s/'//g;
	$string =~ s/expr//;
	$string =~ s/\(//g;
	$string =~ s/\)//g;
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
