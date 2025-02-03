expected := .{
	exit: 0,
	stdout: "Hello, World!",
}

lily := @use("../../lily/lib.hb")

main := fn(): u8 {
	lily.log.print("Hello, World!")
	return 0
}