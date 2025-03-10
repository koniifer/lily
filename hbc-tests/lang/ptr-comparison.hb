expected := .{
	exit: 0,
}

opaque := fn(): ^u8 {
	return @bit_cast(0)
}

opaque2 := fn(): ^u8 {
	return @bit_cast(0)
}

main := fn(): u8 {
	if opaque() != opaque2() {
		r := opaque() ^ opaque2()
		if r == 0 return 2
		return 1
	}
	return 0
}