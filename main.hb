lily.{fmt, log, mem, alloc, target} := @use("lily")

// b: []u8 = idk

main := fn(): void {
	arena := alloc.Arena.new()
	defer arena.deinit()

	// i := 0
	// loop if i == 5 break else {
	// 	// 24 = @size_of(AllocationHeader)
	// 	if arena.alloc(u8, target.page_len() - 24) == null die
	// 	i += 1
	// }

	// b = arena.alloc_zeroed(u8, 1000).?

	// mem.bytes(mem.reverse("Hello, World!")[1..]).take(5).for_each(fn(x: u8): void {
	// 	len := fmt.fmt_int(b, x, 16)
	// 	log.info(b[0..len])
	// 	mem.set(b.ptr, 0, len)
	// })

	c := alloc.Vec(uint, alloc.Arena).new(&arena)
	defer c.deinit()

	loop if c.len() == 100000 break else {
		c.push(1)
	}
}
