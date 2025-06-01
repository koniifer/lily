lily.{fmt, log, mem, alloc, target} := @use("lily")

// c: [100]u8 = idk

// func := fn(x: uint): uint {
// 	return x + 1
// }
// func2 := fn(x: uint): uint {
// 	return x + 2
// }

// main := fn(): uint {
// 	c[0] = 1
// 	fnc: ^u8 = @bit_cast(0x10014a5)
// 	page_size := 0x1000
// 	page: uint = @bit_cast(fnc) & ~(page_size - 1)
// 	@syscall(0xA, page, page_size, 7)
// 	_ = func2(3)
// 	fnc.* = 0x0F
// 	(fnc + 1).* = 0x0B
// 	return func(0)
// }

main := fn(argc: uint, argv: ^^u8): uint {
	ptr := target.alloc(100)
	if ptr == null lily.panic(1)
	@as(^u64, @bit_cast(ptr.?)).* = 73

	ptr2 := target.alloc(100)
	if ptr2 == null lily.panic(2)

	target.rand_fill(ptr.?, 100)

	target.memcopy(ptr2.?, ptr.?, 100)

	val := (ptr2.? + 99).*

	target.dealloc(ptr2.?, 100)
	target.dealloc(ptr.?, 100)
	return val
}
