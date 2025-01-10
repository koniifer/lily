.{Config, Target, Type, log, collections: .{Vec}} := @use("../lib.hb");
.{RawAllocator} := @use("lib.hb")

Allocation := struct {
	ptr: ^void,
	len: uint,
}

// ! THIS ALLOCATOR IS TEMPORARY
SimpleAllocator := struct {
	allocations: Vec(Allocation, RawAllocator),
	raw: RawAllocator,

	$new := fn(): Self {
		raw := RawAllocator.new()
		return .(Vec(Allocation, RawAllocator).new(&raw), raw)
	}
	deinit := fn(self: ^Self): void {
		loop if self.allocations.len() == 0 break else {
			alloced := self.allocations.pop()
			if alloced == null continue
			match Target.current() {
				.LibC => Target.free(alloced.ptr),
				.AbleOS => Target.free(alloced.ptr, alloced.len),
			}
		}

		self.allocations.deinit()
		self.raw.deinit()
		log.debug("deinit: allocator")
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := Target.malloc(count * @sizeof(T))
		if Target.current() == .AbleOS {
			if ptr != null self.allocations.push(.(ptr, count * @sizeof(T)))
		}
		log.debug("allocated")

		return @bitcast(ptr)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := Target.calloc(count * @sizeof(T))
		if Target.current() == .AbleOS {
			if ptr != null self.allocations.push(.(ptr, count * @sizeof(T)))
		}
		return @bitcast(ptr)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		match Target.current() {
			.AbleOS => {
				// temporary optimisation, ableos only gives whole pages.
				// this prevents reallocating 1 page over and over
				if count * @sizeof(T) < Target.PAGE_SIZE return ptr
				alloced := self._find_and_remove(@bitcast(ptr))
				if alloced == null return null
				new_ptr := Target.realloc(@bitcast(ptr), alloced.len, count * @sizeof(T))
				if new_ptr != null {
					self.allocations.push(.(new_ptr, count * @sizeof(T)))
				} else {
					self.allocations.push(alloced)
				}
				return @bitcast(new_ptr)
			},
			.LibC => {
				new_ptr := Target.realloc(@bitcast(ptr), count * @sizeof(T))
				log.debug("reallocated")
				return @bitcast(new_ptr)
			},
		}
	}
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		match Target.current() {
			.AbleOS => {
				alloced := self._find_and_remove(@bitcast(ptr))
				if alloced != null Target.free(@bitcast(ptr), alloced.len)
			},
			.LibC => {
				Target.free(@bitcast(ptr))
			},
		}
		log.debug("freed")
	}
	_find_and_remove := fn(self: ^Self, ptr: ^void): ?Allocation {
		i := 0
		loop if i == self.allocations.len() break else {
			defer i += 1
			alloced := self.allocations.get(i)
			if alloced == null return null
			if alloced.ptr == ptr {
				_ = self.allocations.remove(i)
				return alloced
			}
		}
		return null
	}
}