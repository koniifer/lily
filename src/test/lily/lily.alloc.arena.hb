/*
 * exit: 0
 */
lily := @use("../../lily/lib.hb")

main := fn(argc: int, argv: [][]u8): u8 {
	alloc := lily.alloc.ArenaAllocator.new()
	defer alloc.deinit()

	vec := lily.collections.Vec(u8, lily.alloc.ArenaAllocator).new(&alloc)

	vec.push(69)
	vec.push(69)
	vec.push(69)

	vec2 := lily.collections.Vec(u8, lily.alloc.ArenaAllocator).new(&alloc)

	vec2.push(69)
	vec2.push(69)
	vec2.push(69)

	vec.push(69)
	vec.push(69)
	vec.push(69)

	ptr_one := alloc.alloc(u8, 6)
	ptr_two := alloc.alloc(u8, 18)
	return 0
}
