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

// main := fn(): uint {
// arena := alloc.Arena.new()
// defer arena.deinit()
// vec := collections.Vec(uint, alloc.Arena).new(&arena)
// defer vec.deinit()

// 	i := 0
// 	loop if i == 100 break else {
// 		vec.push(i)
// 		i += 1
// 	}

// 	lily.log.print(vec)

// 	loop if vec.len() == 0 break else {
// 		_ = vec.pop_unchecked()
// 	}

// 	return vec.len()
// 	// arr := u8.[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
// 	// x := mem.Writer(arr)
// 	// if !x.write(u8.[1, 2, 3][..]) {
// 	// 	return 1
// 	// }

// 	// r := lily.Result(u8, u8).err(1)
// 	// v := r.expect_err("oh no")

// 	return 0
// }

main := fn(): uint {
	arena := alloc.Arena.new()
	defer arena.deinit()
	map := collections.HashMap(uint, uint, alloc.Arena, lily.hash.FoldHasher).new(&arena)
	defer map.deinit()

	i := 0
	loop if i == 20 break else {
		_ = map.insert(i, i)
		i += 1
	}

	return 0
}
