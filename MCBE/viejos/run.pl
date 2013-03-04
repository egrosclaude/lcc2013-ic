#!/usr/bin/perl 
$codes = { LD => 2, ST => 3, ADD => 4, SUB => 5, JMP => 6, JZ => 7, HLT => 1, NOP => 0 };
$labels = {IN => 30, OUT => 31};
@lines = ();

sub dec2bin {
	($fld, $num) = @_;
	return sprintf(sprintf("%%0%db", $fld), $num % 256);
}
sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub insttobin {
	($mnem, $arg) = @_;
	$binst = dec2bin(3,$codes->{$mnem});
	$bdat  = dec2bin(5,$arg);
	return $binst.$bdat;
}

sub setlabel { $x = shift; $labels->{$x} = $lnum; }
sub numarg { push @lines, [$lnum++,$1,$2,insttobin($1,$2)]; }
sub noarg { push @lines, [$lnum++,$1,"",insttobin($1,0)]; }
sub lblarg { push @lines, [$lnum++, $1, $2, "LBLARG"]; }
sub data { push @lines, [$lnum++, "", $1, dec2bin(8,$1)]; }

open INFILE, "$ARGV[0]" or die "Falta nombre de archivo";

while(<INFILE>) {
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

close INFILE;

our @MEM = ();
our @PROG = ();

sub printline {
	$lista = shift;
	($nl, $inst, $iarg, $ibin) = @{$lista};
	printf "%2d %4s %3d %s\n", $nl,$inst,$iarg,$ibin;
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
	@PROG[$nl] = [$nl,$inst,$iarg,$ibin];
	@p = @PROG[$nl];
	printline(@p);
	@MEM[$nl]= $ibin;
}
our $IR = 0;
our $PC = 0;
our $A = 0;
our $hlt = 0;
sub interpreta {
	($inst,$data) = @_;


	if($inst eq '010') { #LD
		$addr = bin2dec($data);
		if($addr == 30) {
			printf "Ingrese un dato: ";
			$dato = <STDIN>;
			@MEM[$addr] = dec2bin(8,$dato);
		} 
		$A = @MEM[$addr];
		$PC++;

	}
	if($inst eq '011') { #ST
		$addr = bin2dec($data);
		@MEM[$addr] = dec2bin(8,$A);
		$PC++;
		if($addr == 31) {
			print "SALIDA ".@MEM[$addr];
		}
	}
	if($inst eq '100') { #ADD
		$addr = bin2dec($data);
		$A += @MEM[$addr];
		$PC++;
	}
	if($inst eq '101') { #SUB
		$addr = bin2dec($data);
		$A -= @MEM[$addr];
		$PC++;
	}
	if($inst eq '001') { #HLT
		$hlt = 1;
	}
	if($inst eq '000') { #NOP
		$PC++;
	}
	if($inst eq '110') { #JMP
		$offset = bin2dec($data);
		$PC += $offset;
	}
	if($inst eq '111') { #JZ
		if($A == 0) {
			$offset = bin2dec($data);
			$PC += $offset;
		} else {
			$PC++;
		}
	}
}

sub printstatus {
	print "--------------------------------------\n";
	print "PC:$PC     IR:$IR     A:$A\n";
	foreach $j (0..7) {
		foreach $i (7, 15, 23, 31) {
			$k = $i - $j;
			printf "%3d %8s\t",$k,$MEM[$k];
		}
		print "\n";
	}
	$nada = <STDIN>;
}
		
print 40x'-' . "\n";
$hlt = 0;
while($hlt == 0) {
	die "El PC salió de la memoria: $PC" if($PC < 0 || $PC > 31);
	@p = @PROG[$PC];
	printline(@p);
	$IR = @MEM[$PC];
	$IR =~ /(\d\d\d)(\d\d\d\d\d)/;
	$inst = $1;
	$data = $2;
	interpreta($inst,$data);
	printstatus;
}
