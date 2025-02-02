/*
 * exit: 0
 */

opaque := fn(): ^u8 {
	return @bitcast(0)
}

opaque2 := fn(): ^u8 {
	return @bitcast(0)
}

main := fn(): u8 {
	// ! (libc) (compiler) bug: ptr comparison causes not yet implemented: bool
	if opaque() != opaque2() {
		r := opaque() ^ opaque2()
		// if you get 2 then the world is ending
		if r == 0 return 2
		return 1
	}
	return 0
}