expectations := .{
	return_value: 0,
}

Struct := struct {
	.inner: ?^u8

	modify := fn(self: ^Struct, $T: type): void {
		self.inner = @bit_cast(1)
	}
}

main := fn(): uint {
	a := Struct.(null)
	// ! (compiler) bug: adding type here makes
	// ! self get passed by value and not by ref
	a.modify(void)
	if a.inner == null return 1

	b := Struct.(null)
	Struct.modify(&b, void)
	if b.inner == null return 1
	return 0
}
