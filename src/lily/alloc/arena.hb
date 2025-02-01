.{Config, Target, Type, log, collections: .{Vec}} := @use("../lib.hb");

Allocation := struct {
	ptr: ^u8,
	len: uint,
}

ArenaAllocator := struct {
	ptr: ^u8,
	size: uint,
	allocated: uint,

	new := fn(): Self {
		size := Target.page_size()
		// todo(?): spec should accept ?Self as return type
		ptr := @unwrap(Target.alloc_zeroed(size))
		return .(ptr, size, 0)
	}
	deinit := fn(self: ^Self): void {
		match Target.current() {
			.LibC => Target.dealloc(self.ptr),
			.AbleOS => Target.dealloc(self.ptr, self.size),
		}
		log.debug("deinit: allocator")
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		if self.allocated + count * @sizeof(T) > self.size {
			ptr := Target.realloc(self.ptr, self.size, self.size * 2)
			if ptr == null {
				log.error("Failed to grow arena");
				die
			}
			self.ptr = @unwrap(ptr)
		}
		allocation := self.ptr + self.allocated
		self.allocated = self.allocated + count * @sizeof(T)
		log.debug("allocated")
		return @bitcast(allocation)
	}
	$alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		return self.alloc(T, count)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		log.error("Don't call realloc on the arena allocator");
		die
	}
	dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		log.debug("freed")
	}
	_find_and_remove := fn(self: ^Self, ptr: ^u8): ?Allocation {
		i := 0
		loop if i == self.allocations.len() break else {
			defer i += 1
			alloced := self.allocations.get_unchecked(i)
			if alloced.ptr == ptr {
				_ = self.allocations.swap_remove(i)
				return alloced
			}
		}
		return null
	}
}
