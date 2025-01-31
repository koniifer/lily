/*
 * exit: 0
 */
lily := @use("../../lily/lib.hb")

main := fn(argc: int, argv: [][]u8): u8 {
	alloc := lily.alloc.ArenaAllocator.new()
	defer alloc.deinit()
	ptr_one := alloc.alloc(u8, 6)
	ptr_two := alloc.alloc(u8, 179)
	return 0
}