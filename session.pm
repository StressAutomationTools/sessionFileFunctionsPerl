package session;
use warnings;
use strict;

sub expandPatranList{
	#given a string as in the ID list for a group, returns a dictionary containing entities and the IDs associated with them
	#check returned group for "Unknown", if present, IDs are supplied without label
	my $patranList = $_[0];
	my %group;
	my $currentType = "Unknown";
	my @parts = split(" ", $patranList);
	foreach my $part (@parts){
		if($part =~ m/[a-zA-Z]+/){
			$currentType = $part;
		}
		elsif($part =~ m/(\d+):(\d+):(\d+)/){
			 for (my $n = $1; $n <= $2; $n = $n + $3) {
				push(@{$group{$currentType}}, $n);
			}
		}
		elsif($part =~ m/(\d+):(\d+)/){
			 for (my $n = $1; $n <= $2; $n++) {
				push(@{$group{$currentType}}, $n);
			}
		}
		elsif($part =~ m/(\d+)/){
			push(@{$group{$currentType}}, $1);
		}
		else{
			print "Unexpected value in expandPatranList: $part\n";
		}
	}
	return %group;
}

sub contractPatranList{
	#given a dictionary as output by expandPatranList, returns a string as needed for a group
	#only contracts sequences with a step of 1
	my %group = @_;
	my @types = keys(%group);
	my $outputString = "";
	foreach my $type (@types){
		$outputString = $outputString." ".$type;
		my @IDs = @{$group{$type}};
		@IDs = sort {$a <=> $b} @IDs;
		my $ubound = @IDs - 1;
		my $switch = 0;
		for(my $n = 0; $n <= $ubound; $n++){
			if($n == 0){
				$outputString = $outputString." ".$IDs[$n];
			}
			elsif($n == $ubound){
				if($IDs[$n - 2] == $IDs[$n] - 2){
					$outputString = $outputString.$IDs[$n];
				}
				else{
					$outputString = $outputString." ".$IDs[$n];
				}
			}
			elsif(not($IDs[$n - 1] == $IDs[$n] - 1)){
				$outputString = $outputString." ".$IDs[$n];
				$switch = 0
			}
			elsif($IDs[$n + 1] == $IDs[$n] + 1){
				if(not($switch)){
					$switch = 1;
					$outputString = $outputString.":";
				}
				else{
					#no action
				}
				
			}
			elsif($switch){
				$outputString = $outputString.$IDs[$n];
			}
			else{
				$outputString = $outputString." ".$IDs[$n];
			}
			#currently without contraction
			# $outputString = $outputString." ".$IDs[$n];
		}
	}
	return $outputString;
}

sub testExpandAndContract{
	#tests expand and contract functions, output should be close to input (some additional contraction and sorting takes place)
	my %groups = expandPatranList("Short 1 2 Three 1:3 ThreeNot 1 4 8 Range 1:50 RangeAtEnd 1 4 6 7:10 LastNotInRange 1 3:7 9 NoRange 2 5 9 6 2 6");
	print contractPatranList(%groups)."\n";

}


sub arrayToArrayString{
	#warning, decimal values should be provided as strings as a decimal .0 may get cut off and output an integer
	my @array = @_;
	my $ubound = @array - 1;
	my $arrayString = "";
	for(my $n = 0; $n <= $ubound; $n++){
		unless(($array[$n] =~ m/^[+-]?\d+$/ or $array[$n] =~ m/^[+-]?\d+\.\d*[Ee]?[+-]?\d*$/) or substr($array[$n], 0, 1) eq "\""){
			#quote strings
			$array[$n] = "\"".$array[$n]."\"";
		}
		if($ubound == 0){
			$arrayString = "\[ ".$array[0]." \]";
		}
		else{
			if($n == 0){
				$arrayString = "\[ ".$array[$n];
			}
			elsif($n == $ubound){
				$arrayString = $arrayString." , ".$array[$n]." \]";
			}
			else{
				$arrayString = $arrayString." , ".$array[$n];
			}
		}
	}
	unless(@array){
		$arrayString = "\[ \]";
	}
	return $arrayString;
}

sub testArrayToArrayString{
	#an empty array
	my @array;
	print arrayToArrayString(@array)."\n";
	#single value array
	@array = (1);
	print arrayToArrayString(@array)."\n";
	#multiple values, text, integer, various decimal
	@array = (1, 10000000, "a text string", "1.0", "1.", 0., "1004.e+7", "1004.+6", -75., -14, "10.-7", "10.0E-7");
	print arrayToArrayString(@array)."\n";
}

#unchecked from this point on

sub splitString{
	#this command can be improved to reduce number of string splits and use all 80 characters when not splitting strings
	#needs testing with actual commands that are then tested in patran
	my $command = $_[0];
	my $outputstring = "";
	while(length($command) > 80){
		my $substring = substr($command, 0, 73);
		my $count = () = $substring =~ /\"/g;
		if($count % 2 == 0){
			$outputstring = $outputstring.$substring." \@\n";
			$command = substr($command, 73);
		}
		else{
			$outputstring = $outputstring.$substring."\" \/\/ \@\n";
			$command = "\"".substr($command, 73);
		}
	}
	$outputstring.$command."\n";
}


sub testSplitString{
	my $command = "a_long_command( [ \"Yes... yes. This is a fertile land, and we will thrive. We will rule over all this land, and we will call it... This Land.\", \"I think we should call it... your grave!\", \"Ah! Curse your sudden but inevitable betrayal!\", \"Ha ha ha! Mine is an evil laugh! Now DIE!\", \"Oh no, God, oh dear God in heaven...\" ], 2336553255, 235411605143, 2318548135132321, 528641321321834545, 2316846754132168432164321321, 1987412313218425132148132, 1864332132187414321688744351321, 684132103214681384323138, 31358432131381513)";
	print splitString($command);
}


sub commandString{
	# order of inputs: command, values for command in correct order, all in one array of strings
	#assemble command
	my @values = @_;
	my $command = shift(@values);
	my $commandString = "";
	$commandString = $command."( ";
	my $ubound = @values - 1;
	my $outputString;
	for(my $n = 0; $n <= $ubound; $n++){
		my $substring = $values[$n];
		if($substring =~ m/\[.*\]/){
			#inputstring is array
		}
		else{
			#add quotes to substring
			unless(substr($substring, 0, 1) eq "\""){
				$substring = "\"".$substring."\"";
			}
		}
		if($n == 0){
			$commandString = $commandString.$substring;
		}
		else{
			$commandString = $commandString." , ".$substring;
		}
		if($n == $ubound){
			$commandString = $commandString." )";
		}
	}
	if(length($commandString) <= 80){
		$outputString = $commandString."\n";
	}
	else{
		$outputString = splitString($commandString);
	}
	return $outputString;
}

sub TestCommandString{
	print commandString("theCommand", "This is a string", "[1234 ,1234 ,234 ,1234]", "[ \"string\", \"string\", \"string\", \"string\", \"string\", \"string\", \"string\", \"string\", \"string\", \"string\" ]");
}

1;
