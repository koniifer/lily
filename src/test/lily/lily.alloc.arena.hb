/*
 * exit: 0
 */
lily := @use("../../lily/lib.hb")

main := fn(argc: int, argv: [][]u8): u8 {
	alloc := lily.alloc.ArenaAllocator.new()
	ptr_one := alloc.alloc(u8, 6)
	ptr_two := alloc.alloc(u8, 179)
	alloc.deinit()
	return 0
}
