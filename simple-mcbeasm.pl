#!/usr/bin/perl -n 

$codes = { LD => 2, ST => 3, ADD => 4, SUB => 5, JMP => 6, JZ => 7, HLT => 1, NOP => 0 };

sub numtobin {
	($fld, $num) = @_;
	$mask = sprintf("%%0%db", $fld);
	return sprintf($mask, $num);
}

sub insttobin {
	($mnem, $arg) = @_;
	$binst = numtobin(3,$codes->{$mnem});
	$bdat  = numtobin(5,$arg);
	return $binst.$bdat;
}

/([A-Z]+) (\d*)/ and printf "%2d %4s %3d %s\n",$lnum++,$1,$2,insttobin($1,$2);
/([A-Z]+) *$/ and printf "%2d %4s %3s %s\n",$lnum++,$1,"",insttobin($1,$2);
/^(\d+)/ and printf "%2d %4s %3d %s\n",$lnum++,"",$1,numtobin(8,$1);
