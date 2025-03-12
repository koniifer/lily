lily.{fmt, log, mem, alloc, target} := @use("../../src/lib.hb")

main := fn(): void {
	arena := alloc.Arena.new()
	defer arena.deinit()

	_ = arena.alloc(u8, 1).?

	iter := mem.bytes(mem.reverse("Hello, World!")[1..]).take(5)
	str := iter.collect_vec(&arena)
}
