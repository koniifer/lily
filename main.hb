lily.{target, log, mem} := @use("lily")

FunkyTown := struct {
	.is_null: bool;
	.ptr: ^u8;
}

main := fn(): void {
	a := "Hello, World!"
	b := mem.bytes(a).map(fn(x: u8): u8 return x + 2)
	c := b.next().val
	if c != 0x48 + 2 die

	// a := target.alloc(1000)[0..1000]
	// // todo: remove @as()
	// if @as(uint, @bit_cast(a.ptr)) == 0 {
	// 	log.error("alloced is null")
	// 	die
	// }

	// mem.copy(a.ptr, "Hello, World!".ptr, 13)

	// if !mem.equals(a[0..13], "Hello, World!") {
	// 	log.error("badness")
	// 	die
	// }

	// log.info(a[0..13])

	// target.dealloc(a.ptr, 1000)
}
