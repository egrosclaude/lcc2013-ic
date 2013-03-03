sub dec2sigmag {
        ($fld, $num) = @_;
        $mask = sprintf("%%0%db", $fld);
	
	if($num < 0) {
		print "Es neg";
		$num = -$num + 16;
	}
	$num %= 32;
        $s = sprintf($mask, $num);

        return $s;
}

for( $a = -15; $a < 16; $a++) {
printf "%3d %s\n", $a,dec2sigmag(5,$a);
}

