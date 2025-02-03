expected := .{
	exit: 0,
	stdout: "Hello, World!",
}

lily := @use("../../lily/lib.hb")

main := fn(): u8 {
	str := lily.string.chars("Hello, ").intersperse(
		lily.string.chars("World!"),
	).collect([13]u8)

	if str != null {
		lily.log.info(@as([13]u8, str)[..])
	} else {
		lily.panic("failed to collect array")
	}

	return 0
}