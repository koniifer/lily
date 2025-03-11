expectations := .{
    return_value: 0,
}

opaque := fn(v: @Any()): bool {
	return v < 0
}

opaque2 := fn(v: @Any()): bool {
	return v > 0
}

main := fn(): u8 {
	v: int = -10

	if !opaque(v) return 1
	if !@inline(opaque, v) return 1
	if opaque2(v) return 1
	if @inline(opaque2, v) return 1

	return 0
}
