.{Config, Target, Type, log, collections: .{Vec}} := @use("../lib.hb");

RawAllocator := struct {
	ptr: ^void,
	size: uint,
	$new := fn(): Self return .(Type(^void).uninit(), 0)
	deinit := fn(self: ^Self): void {
		self.free(void, Type(^void).uninit());
		*self = Self.new()
		log.debug("deinit: raw allocator")
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := Target.malloc(count * @sizeof(T))
		if ptr != null {
			self.ptr = ptr
			self.size = count * @sizeof(T)
		}
		log.debug("allocated raw")
		return @bitcast(ptr)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := Target.calloc(count * @sizeof(T))
		if ptr != null {
			self.ptr = ptr
			self.size = count * @sizeof(T)
		}
		return @bitcast(ptr)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		if self.size == 0 return null
		log.debug("reallocated raw")
		match Target.current() {
			.LibC => {
				new_ptr := Target.realloc(self.ptr, count * @sizeof(T))
				if new_ptr != null {
					self.ptr = new_ptr
					self.size = count * @sizeof(T)
				}
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
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if self.size == 0 return;
		match Target.current() {
			.LibC => Target.free(self.ptr),
			.AbleOS => Target.free(self.ptr, self.size),
		}
		log.debug("freed raw")
	}
}