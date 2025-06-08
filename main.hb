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

// init_window := fn(width: u16, height: u16, title: ^u8): void @import("InitWindow")
// window_should_close := fn(): bool @import("WindowShouldClose")
// close_window := fn(): void @import("CloseWindow")
// clear_background := fn(c: u32): void @import("ClearBackground")
// begin_drawing := fn(): void @import("BeginDrawing")
// end_drawing := fn(): void @import("EndDrawing")
// set_trace_loglevel := fn(level: u8): void @import("SetTraceLogLevel")

// Colour := struct align(1){.r: u8; .g: u8; .b: u8; .a: u8}

// main := fn(): uint {
// 	set_trace_loglevel(4)
// 	init_window(800, 450, "raylib [core] example in hblang!".ptr)

// 	c: u32 = 0
// 	t := 0.0

// 	loop if window_should_close() {
// 		break
// 		close_window()
// 	} else {
// 		target.rand_fill(@bit_cast(&c), @size_of(Colour))
// 		begin_drawing()
// 		clear_background(c)
// 		end_drawing()
// 	}

// 	return 0
// }

// main := fn(): uint {
// 	arena := lily.alloc.Arena.new()
// 	defer arena.deinit()

// 	map := lily.collections.HashMap(
// 		uint,
// 		uint,
// 		lily.alloc.Arena,
// 		lily.hash.RapidHasher,
// 	).new(&arena)
// 	defer map.deinit()

// 	i := 0
// 	loop if i == 10 break else {
// 		_ = map.insert(i, 0)
// 		i += 1
// 	}

// 	lily.log.print(map)

// 	return 0
// }


main := fn(): uint {
	x := lily.result.Result(uint, uint).err(1).map(fn(y: uint): uint return y + 1).unwrap()
	return x
}