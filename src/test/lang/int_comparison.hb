/*
 * exit: 0
 */

opaque := fn(v: @Any()): bool {
	return v < 0
}

opaque2 := fn(v: @Any()): bool {
	return v > 0
}

main := fn(): u8 {
	v: int = -10

	// ! (compiler) bug: opaque(v) is incorrectly false
	if !opaque(v) return 1
	if !@inline(opaque, v) return 1
	// ! (compiler) bug: opaque2(v) is incorrectly true
	if opaque2(v) return 1
	if @inline(opaque2, v) return 1

	return 0
}