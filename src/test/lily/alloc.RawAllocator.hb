/*
 * exit: 0
 */

lily := @use("../../lily/lib.hb")

main := fn(): uint {
	allocator := lily.alloc.RawAllocator.new()
	defer allocator.deinit()
	b := allocator.alloc(u8, 100)
	if b == null return 1
	c := allocator.alloc(u8, 100)
	if c == null return 1
	d := allocator.realloc(u8, c.ptr, 100)
	if d == null return 1
	// ! d.ptr != c.ptr, but d.ptr ^ c.ptr == 0... nice.
	if d.ptr != c.ptr return @as(uint, @bitcast(d.ptr ^ c.ptr))
	// ! 5 specifically causes a compiler error
	// ! set this to 1 after it gets fixed to demonstrate bug above
	return 5
}