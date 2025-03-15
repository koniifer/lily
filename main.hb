lily.{fmt, log, mem, alloc, target} := @use("lily")

main := fn(): void {
	arena := alloc.Arena.new()
	defer arena.deinit()

	iter := mem.iter(mem.reverse("Hello, World!")[1..]).take(5)
	str := iter.collect_vec(&arena)
	log.info(str.slice)
}
