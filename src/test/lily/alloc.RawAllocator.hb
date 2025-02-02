/*
 * exit: 0
*/

lily := @use("../../lily/lib.hb")

main := fn(): u8 {
	allocator := lily.alloc.RawAllocator.new()
	defer allocator.deinit()
	b := allocator.alloc(u8, 100)
	if b == null return 1
	c := allocator.alloc(u8, 100)
	if c == null return 1
	d := allocator.realloc(u8, c.ptr, 100)
	if d == null return 1
	if d.ptr != c.ptr return 1
	return 0
}