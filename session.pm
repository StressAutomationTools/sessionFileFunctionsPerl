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

#unchecked from this point on

1;
