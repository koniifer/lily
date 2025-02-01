.{Config, Target, Type, log, collections: .{Vec}, alloc: .{RawAllocator}} := @use("../lib.hb");

Allocation := struct {
	ptr: ^u8,
	len: uint,
}

ArenaAllocator := struct {
	ptr: ^u8,
	size: uint,
	allocated: uint,
	allocations: Vec(Allocation, RawAllocator),
	raw: RawAllocator,

	new := fn(): Self {
		size := Target.page_size()
		// todo(?): spec should accept ?Self as return type
		ptr := @unwrap(Target.alloc_zeroed(size))
		raw := RawAllocator.new()
		vec := Vec(Allocation, RawAllocator).new(&raw)
		return .(ptr, size, 0, vec, raw)
	}
	deinit := fn(self: ^Self): void {
		Target.dealloc(self.ptr, self.size)
		self.allocations.deinit()
		self.raw.deinit()
		log.debug("deinit: allocator")
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		if self.allocated + count * @sizeof(T) > self.size {
			// ! (libc) (compiler) bug: null check broken. unwrapping.
			self.ptr = @unwrap(Target.realloc(self.ptr, self.size, self.size * 2))
			self.size = self.size * 2
		}
		allocation := self.ptr + self.allocated
		self.allocations.push(.(allocation, count * @sizeof(T)))
		self.allocated = self.allocated + count * @sizeof(T)
		log.debug("allocated")
		return @bitcast(allocation)
	}
	$alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		return self.alloc(T, count)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		old_size := self._find_size(ptr)
		if old_size == null return null

		if old_size > @sizeof(T) * count {
			if Config.debug_assertions() {
				log.warn("arena allocator: new_size is smaller than old_size")
			}
			return ptr
		}
		new_ptr := @unwrap(self.alloc(T, count))
		_ = Target.memcpy(new_ptr, ptr, old_size)
		return new_ptr
	}
	dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		log.debug("freed")
	}

	_find_size := fn(self: ^Self, ptr: ^u8): ?uint {
		i := 0
		loop if i == self.allocations.len() break else {
			defer i += 1
			alloced := self.allocations.get_unchecked(i)
			return alloced.len
		}
		return null
	}
}
