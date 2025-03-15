expectations := .{
	times_out: true,
}

opaque := fn(): ^u8 {
	return @bit_cast(1)
}

inner := fn(ptr: ^u8): void {
	if ptr != @bit_cast(1) die
}

main := fn(): void {
	ptr := opaque()

	loop {
		inner(ptr)
	}
}
