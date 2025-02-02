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
		if Target.calculate_pages(self.size) == Target.calculate_pages(count * @sizeof(T)) {
			self.size = count * @sizeof(T)
			return @bitcast(self.ptr)
		}
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		ptr := @unwrap(Target.alloc(count * @sizeof(T)))
		self.ptr = ptr
		self.size = count * @sizeof(T)

		log.debug("allocated: raw")
		return @bitcast(ptr)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		if Target.calculate_pages(self.size) == Target.calculate_pages(count * @sizeof(T)) {
			self.size = count * @sizeof(T)
			return @bitcast(self.ptr)
		}
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		ptr := @unwrap(Target.alloc_zeroed(count * @sizeof(T)))
		self.ptr = ptr
		self.size = count * @sizeof(T)

		log.debug("allocated: raw")
		return @bitcast(ptr)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		if self.size == 0 return null
		if Target.calculate_pages(self.size) == Target.calculate_pages(count * @sizeof(T)) {
			self.size = count * @sizeof(T)
			return @bitcast(self.ptr)
		}
		log.debug("reallocated: raw")
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		new_ptr := @unwrap(Target.realloc(self.ptr, self.size, count * @sizeof(T)))
		self.ptr = new_ptr
		self.size = count * @sizeof(T)
		return @bitcast(new_ptr)
	}
	// ! INLINING THIS FUNCTION CAUSES MISCOMPILATION!! DO NOT INLINE IT!! :) :) :)
	dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		if self.size == 0 return;
		Target.dealloc(self.ptr, self.size)
		log.debug("deallocated: raw")
	}
}