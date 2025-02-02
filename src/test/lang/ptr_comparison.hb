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
		return 1
	}
	return 0
}