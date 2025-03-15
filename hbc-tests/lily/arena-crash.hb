expectations := .{
	return_value: 5,
	ecalls: .(
		.(3, 2): 1,
	),
}

lily.{mem, alloc} := @use("../../src/lib.hb")

main := fn(): uint {
	arena := alloc.Arena.new()
	defer arena.deinit()

	_ = arena.alloc(u8, 1).?

	iter := mem.iter(mem.reverse("Hello, World!")[1..]).take(5)
	str := iter.collect_vec(&arena)
	return str.len()
}
