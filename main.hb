lily.{fmt, log, mem, alloc, target} := @use("lily")

main := fn(): uint {
	ptr := target.alloc(100)
	if ptr == null lily.panic(1)
	@as(^u64, @bit_cast(ptr.?)).* = 73

	ptr2 := target.realloc(ptr.?, 100, 255)
	if ptr2 == null lily.panic(2)

	target.rand_fill(ptr2.?, 255)

	val := ptr2.?.*

	target.dealloc(ptr2.?, 255)
	return val
}
