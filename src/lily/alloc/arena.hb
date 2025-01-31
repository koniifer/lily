.{Config, Target, Type, log, collections: .{Vec}} := @use("../lib.hb");

Allocation := struct {
	ptr: ^u8,
	len: uint,
}

ArenaAllocator := struct {
	ptr: ^u8,
	size: uint,
	allocated: uint,

	$new := fn(size: uint): Self {
		allocated := idk
		if size == 0 {
			allocated = Target.page_size()
		} else {
			allocated = size
		}
		ptr := Target.alloc_zeroed(size)
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
		if count * @sizeof(T) + self.allocated > self.size {
			log.error("You allocated more memory on the arena than the arena had.");
			die
		}
		allocation := self.ptr + self.allocated
		self.allocated = self.allocated + count * @sizeof(T)
		log.debug("allocated")
		return @bitcast(allocation)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
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
