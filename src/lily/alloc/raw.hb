.{Config, Target, Type, log, collections: .{Vec}} := @use("../lib.hb");

RawAllocator := struct {
	ptr: ^u8,
	size: uint,
	$new := fn(): Self return .(Type(^u8).uninit(), 0)
	deinit := fn(self: ^Self): void {
		self.dealloc(u8, Type(^u8).uninit());
		*self = Self.new()
		log.debug("deinit: raw allocator")
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		ptr := @unwrap(Target.alloc(count * @sizeof(T)))

		self.ptr = ptr
		self.size = count * @sizeof(T)

		log.debug("allocated raw")
		return @bitcast(ptr)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		ptr := @unwrap(Target.alloc_zeroed(count * @sizeof(T)))
		self.ptr = ptr
		self.size = count * @sizeof(T)

		return @bitcast(ptr)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		if self.size == 0 return null
		log.debug("reallocated raw")
		match Target.current() {
			.LibC => {
				// ! (libc) (compiler) bug: null check broken. unwrapping.
				new_ptr := @unwrap(Target.realloc(self.ptr, count * @sizeof(T)))
				// if new_ptr != null {
				self.ptr = new_ptr
				self.size = count * @sizeof(T)
				// }
				return @bitcast(new_ptr)
			},
			.AbleOS => {
				new_ptr := Target.realloc(self.ptr, self.size, count * @sizeof(T))
				if new_ptr != null {
					self.ptr = new_ptr
					self.size = count * @sizeof(T)
				}
				return @bitcast(new_ptr)
			},
		}
	}
	// ! INLINING THIS FUNCTION CAUSES MISCOMPILATION!! DO NOT INLINE IT!! :) :) :)
	dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		if self.size == 0 return;
		match Target.current() {
			.LibC => Target.dealloc(self.ptr),
			.AbleOS => Target.dealloc(self.ptr, self.size),
		}
		log.debug("freed raw")
	}
}