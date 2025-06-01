lily.{fmt, log, mem, alloc, target, collections} := @use("lily")

// func := fn(x: uint): uint {
// 	return x + 1
// }

// main := fn(): uint {
// 	fnc: ^u8 = @bit_cast(0x10014a5)
// 	page_size := 0x1000
// 	page: uint = @bit_cast(fnc) & ~(page_size - 1)
// 	@syscall(0xA, page, page_size, 7)
// 	fnc.* = 0xC3
// 	return func(0)
// }

main := fn(): uint {
	// ptr := target.alloc(100)
	// if ptr == null lily.panic(1)
	// @as(^u64, @bit_cast(ptr.?)).* = 73

	// ptr2 := target.alloc(100)
	// if ptr2 == null lily.panic(2)

	// target.rand_fill(ptr.?, 100)

	// target.memcopy(ptr2.?, ptr.?, 100)

	// val := (ptr2.? + 99).*

	// target.dealloc(ptr2.?, 100)
	// target.dealloc(ptr.?, 100)
	// return val

	// x := lily.hash.FoldHasher.default()
	// x.write(100)
	// return x.finish()
	log.print(@as(int, 50))
	return 0
}
