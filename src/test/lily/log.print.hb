/*
 * stdout: Hello, World!
 * exit: 0
 */

lily := @use("../../lily/lib.hb")

main := fn(): u8 {
	lily.log.print("Hello, World!")
	return 0
}