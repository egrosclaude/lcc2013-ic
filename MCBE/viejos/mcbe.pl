#!/usr/bin/perl 

$codes = { LD => 2, ST => 3, ADD => 4, SUB => 5, JMP => 6, JZ => 7, HLT => 1, NOP => 0 };
$labels = {IN => 30, OUT => 31};
@lines = ();

sub numtobin {
	($fld, $num) = @_;
	return sprintf(sprintf("%%0%db", $fld), $num % 256);
}

sub insttobin {
	($mnem, $arg) = @_;
	$binst = numtobin(3,$codes->{$mnem});
	$bdat  = numtobin(5,$arg);
	return $binst.$bdat;
}

sub setlabel { $x = shift; $labels->{$x} = $lnum; }
sub numarg { push @lines, [$lnum++,$1,$2,insttobin($1,$2)]; }
sub noarg { push @lines, [$lnum++,$1,"",insttobin($1,0)]; }
sub lblarg { push @lines, [$lnum++, $1, $2, "LBLARG"]; }
sub data { push @lines, [$lnum++, "", $1, numtobin(8,$1)]; }


while(<STDIN>) {
	/^([A-Z]+[0-9]*):/ and setlabel($1);
	/^ *\t*([A-Z]+) *$/ and noarg($1);
	/^ *\t*([A-Z]+) +([0-9]+)/ and numarg($1,$2);
	/^ *\t*([A-Z]+) +([A-Z]+[0-9]*)/ and lblarg($1,$2);
	/^ *\t*(\d+)/ and data($1);
	/^[A-Z]+[0-9]*: *\t*+([A-Z]+) *$/ and noarg($1);
	/^[A-Z]+[0-9]*: *\t*+([A-Z]+) +([0-9]+)/ and numarg($1,$2);
	/^[A-Z]+[0-9]*: *\t*+([A-Z]+) +([A-Z]+[0-9]*)/ and lblarg($1,$2);
	/^[A-Z]+[0-9]*: *\t*(\d+)/ and data($1);
}

foreach $line (@lines) {
	@l = @{$line};
	($nl, $inst, $arg, $bin) = @l;
	if($bin eq "LBLARG") {
		$iarg  = $labels->{$arg};
		$ibin = insttobin($inst,$iarg);
	} else {
		$iarg = $arg; $ibin = $bin;
	}
	printf "%2d %4s %3d %s\n", $nl,$inst,$iarg,$ibin;
}
__END__

