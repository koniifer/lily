.{Config, Target, Type, log, collections: .{Vec}} := @use("../lib.hb");

RawAllocator := struct {
	slice: []u8,
	$new := fn(): Self return .(Type([]u8).uninit())
	$deinit := fn(self: ^Self): void {
		self.dealloc(void, Type(^void).uninit())
	}
	$alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?[]T {
		return Self._alloc_common(self, T, count, true)
	}
	$alloc := fn(self: ^Self, $T: type, count: uint): ?[]T {
		return Self._alloc_common(self, T, count, false)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?[]T {
		size := count * @sizeof(T);
		if size == 0 return Type([]T).uninit();
		if self.slice.len == 0 return null;

		if Target.calculate_pages(self.slice.len) >= Target.calculate_pages(size) {
			return @as(^T, @bitcast(self.slice.ptr))[0..count]
		}

		new_ptr := Target.realloc(self.slice.ptr, self.slice.len, size);
		if new_ptr == null return null
		self.slice = @as(^u8, new_ptr)[0..size];
		log.debug("reallocated: raw");
		return @as(^T, @bitcast(new_ptr))[0..count]
	}
	// ! INLINING THIS FUNCTION CAUSES MISCOMPILATION!! DO NOT INLINE IT!! :) :) :)
	dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		if self.slice.len > 0 {
			Target.dealloc(self.slice.ptr, self.slice.len)
			log.debug("deallocated: raw")
		};
		*self = Self.new()
	}
	_alloc_common := fn(self: ^Self, $T: type, count: uint, zeroed: bool): ?[]T {
		size := count * @sizeof(T);
		if size == 0 return Type([]T).uninit();

		if Target.calculate_pages(self.slice.len) >= Target.calculate_pages(size) {
			return @as(^T, @bitcast(self.slice.ptr))[0..count]
		}

		ptr := Type(?^u8).uninit()
		if zeroed {
			ptr = Target.alloc_zeroed(size)
		} else {
			ptr = Target.alloc(size)
		}
		if ptr == null return null

		if self.slice.len > 0 {
			Target.dealloc(self.slice.ptr, self.slice.len)
		}

		self.slice = @as(^u8, ptr)[0..size]
		log.debug("allocated: raw")
		return @as(^T, @bitcast(ptr))[0..count]
	}
}