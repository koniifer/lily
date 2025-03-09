lily.{target, log, mem, fmt, alloc} := @use("lily")

b: []u8 = idk

main := fn(): void {
	a := target.alloc(1000)
	if a == null die
	b = @as(^u8, @bit_cast(a.?))[0..1000]
	mem.bytes(mem.reverse("Hello, World!")[1..]).take(5).for_each(fn(x: u8): void {
		len := fmt.fmt_int(b, x, 16)
		log.info(b[0..len])
		mem.set(b.ptr, 0, len)
	})
}
