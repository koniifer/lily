expected := .{
	exit: 0,
}

A := struct {
	inner: u8,
}

opaque := fn(): bool {
	return true
}

divergent := fn(): ?A {
	if opaque() {
		return .(0)
	}
	return null
}

main := fn(): u8 {
	a := divergent()
	if a.inner != 0 return 1
	b := @inline(divergent)
	if b.inner != 0 return 1
	return 0
}