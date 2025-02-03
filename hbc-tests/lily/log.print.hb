expected := .{exit: 0, timeout: 10, stdout: "Hello, World!"}

lily := @use("../../src/lily/lib.hb")

main := fn(): u8 {
	lily.log.print("Hello, World!")
	return 0
}