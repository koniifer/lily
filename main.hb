lily.{fmt, log, mem, alloc, target} := @use("lily")

b: []u8 = idk

main := fn(): void {
	arena := alloc.Arena.new()
	defer arena.deinit()

	b = arena.alloc(u8, 1).?

	iter := mem.bytes(mem.reverse("Hello, World!")[1..]).take(5)
	str := iter.collect_vec(&arena)
	log.info(str.slice)
}
