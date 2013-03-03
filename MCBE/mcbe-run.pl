#!/usr/bin/perl 
$codes = { LD => 2, ST => 3, ADD => 4, SUB => 5, JMP => 6, JZ => 7, HLT => 1, NOP => 0 };
$labels = {IN => 30, OUT => 31};
@lines = ();

sub dec2bin {
	($fld, $num) = @_;
	$mask = sprintf("%%0%db", $fld);
	$s = sprintf($mask, $num);
	return $s;
}
sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}
sub dec2sigmag {
        ($fld, $num) = @_;
        $mask = sprintf("%%0%db", $fld);
        if($num < 0) {
                $num = -$num + 16;
        }
        $num %= 32;
        $s = sprintf($mask, $num);
        return $s;
}

sub sigmag2dec {
	$bin = shift;
	$n = bin2dec($bin);
	if($n > 16) {
		$n -= 16;
		$n = -$n;
	}
	return $n;
}

sub insttobin {
	($mnem, $arg) = @_;
	$binst = dec2bin(3,$codes->{$mnem});
	if($mnem =~ /JMP|JZ/) {
		$bdat = dec2sigmag(5,$arg);
	} else {
		$bdat  = dec2bin(5,$arg);
	}
	return $binst.$bdat;
}

sub setlabel { $x = shift; $labels->{$x} = $lnum; }
sub numarg { ($inst,$arg) = @_; push @lines, [$lnum++,$inst,$arg,insttobin($inst,$arg)]; }
sub noarg { $inst = shift; push @lines, [$lnum++,$inst,"",insttobin($inst,0)]; }
sub lblarg { ($inst,$lbl) = @_; push @lines, [$lnum++, $inst, $lbl, "LBLARG"]; }
sub data { $data = shift; push @lines, [$lnum++, "", $data, dec2bin(8,$data)]; }

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
	if($inst =~ /JMP|JZ/) {
		printf "%2d %4s %+3d %s\n", $nl,$inst,$iarg,$ibin;
	} else {
		printf "%2d %4s %3d %s\n", $nl,$inst,$iarg,$ibin;
	}
}

foreach $line (@lines) {
	@l = @{$line};
	($nl, $inst, $arg, $bin) = @l;
	if($bin eq "LBLARG") {
		$arg  = $labels->{$arg};
	} 
	if($inst =~ /JMP|JZ/) {
		$arg= $arg - $nl;
	} 
	$ibin = insttobin($inst,$arg);
	@PROG[$nl] = [$nl,$inst,$arg,$ibin];
	@p = @PROG[$nl];
	printline(@p);
	@MEM[$nl]= $ibin;
}
print "---------------------------------------------------\n";
our $IR = 0;
our $PC = 0;
our $A = 0;
our $hlt = 0;
sub interpreta {
	$my_IR = shift;
	$my_IR =~ /(\d\d\d)(\d\d\d\d\d)/;
	$inst = $1;
	$data = $2;

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
		#printf "A = %s dec2bin = %s \n",$A, dec2bin(8,$A);
		@MEM[$addr] = dec2bin(8,bin2dec($A));
		$PC++;
		if($addr == 31) {
			printf "SALIDA: $s\n",@MEM[$addr];
			$nada = <STDIN>;
		}
	}
	if($inst eq '100') { #ADD
		$addr = bin2dec($data);
		$m = bin2dec(@MEM[$addr]);
		$A = dec2bin(8,bin2dec($A) + $m);
		$PC++;
	}
	if($inst eq '101') { #SUB
		$addr = bin2dec($data);
		$m = bin2dec(@MEM[$addr]);
		$A = dec2bin(8,bin2dec($A) - $m);
		$PC++;
	}
	if($inst eq '001') { #HLT
		$hlt = 1;
	}
	if($inst eq '000') { #NOP
		$PC++;
	}
	if($inst eq '110') { #JMP
		$offset = sigmag2dec($data);
		$PC += $offset;
	}
	if($inst eq '111') { #JZ
		if(bin2dec($A) == 0) {
			$offset = sigmag2dec($data);
			$PC += $offset;
		} else {
			$PC++;
		}
	}
}

sub printstatus {
	print "---------------------------------------------------\n";
	print "PC:$PC              IR:$IR            A:$A\n";
	print "---------------------------------------------------\n";
	foreach $j (0..7) {
		foreach $i (7, 15, 23, 31) {
			$k = $i - $j;
			printf "%3d %8s\t",$k,$MEM[$k];
		}
		print "\n";
	}
	print "---------------------------------------------------\n";
	$nada = <STDIN>;
}
		
# Ciclo de instruccion
$hlt = 0;
while($hlt == 0) {
	die "El PC salió de la memoria: $PC" if($PC < 0 || $PC > 31);
	@p = @PROG[$PC];
	printline(@p);
	$nada = <STDIN>;
	$IR = @MEM[$PC];
	interpreta($IR);
	printstatus;
}

print "Programa Terminado\n";
