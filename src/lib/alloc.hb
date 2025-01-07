.{collections: .{SparseVec, Vec}, target, target_c_native, target_hbvm_ableos, DEBUG, Type, log} := @use("lib.hb")

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
			if target == target_c_native {
				target.free(alloced.ptr)
			} else if target == target_hbvm_ableos {
				target.free(alloced.ptr, alloced.len)
			}
		}
		self.allocations.deinit()
		self.raw.deinit()
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := target.malloc(count * @sizeof(T))
		if target == target_hbvm_ableos {
			if ptr != null self.allocations.push(.(ptr, count * @sizeof(T)))
		}
		if DEBUG {
			log.debug("allocated")
		}
		return @bitcast(ptr)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := target.calloc(count * @sizeof(T))
		if target == target_hbvm_ableos {
			if ptr != null self.allocations.push(.(ptr, count * @sizeof(T)))
		}
		return @bitcast(ptr)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		if target == target_hbvm_ableos {
			// temporary optimisation, ableos only gives whole pages.
			// this prevents reallocating 1 page over and over
			if count * @sizeof(T) < target.PAGE_SIZE return ptr
			alloced := self._find_and_remove(@bitcast(ptr))
			if alloced == null return null
			new_ptr := target.realloc(@bitcast(ptr), alloced.len, count * @sizeof(T))
			if new_ptr != null self.allocations.push(.(new_ptr, count * @sizeof(T))) else self.allocations.push(alloced)
			return @bitcast(new_ptr)
		} else if target == target_c_native {
			new_ptr := target.realloc(@bitcast(ptr), count * @sizeof(T))
			if DEBUG {
				log.debug("reallocated")
			}
			return @bitcast(new_ptr)
		}
	}
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if target == target_c_native {
			target.free(@bitcast(ptr))
			if DEBUG {
				log.debug("freed")
			}
		} else if target == target_hbvm_ableos {
			alloced := self._find_and_remove(@bitcast(ptr))
			if alloced == null return;
			target.free(@bitcast(ptr), alloced.len)
		}
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

// ! THIS ALLOCATOR IS *ALSO* TEMPORARY
RawAllocator := struct {
	ptr: ^void,
	size: uint,
	$new := fn(): Self return .(Type(^void).uninit(), 0)
	deinit := fn(self: ^Self): void {
		if target == target_c_native {
			// ! (compiler) bug: comparing `self.ptr != Type(^void).uninit()` rather than `self.size == 0`
			//		causes condition to never be true (even though it is)
			if self.size != 0 target.free(self.ptr)
		} else if target == target_hbvm_ableos {
			if self.size != 0 target.free(self.ptr, self.size)
		};
		*self = Self.new()
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := target.malloc(count * @sizeof(T))
		if ptr != null {
			self.ptr = ptr
			self.size = count * @sizeof(T)
		}
		return @bitcast(ptr)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := target.calloc(count * @sizeof(T))
		if ptr != null {
			self.ptr = ptr
			self.size = count * @sizeof(T)
		}
		return @bitcast(ptr)
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, count: uint): ?^T {
		if target == target_hbvm_ableos {
			new_ptr := target.realloc(self.ptr, self.size, count * @sizeof(T))
			if new_ptr != null {
				self.ptr = new_ptr
				self.size = count * @sizeof(T)
			}
			return @bitcast(new_ptr)
		} else if target == target_c_native {
			new_ptr := target.realloc(self.ptr, count * @sizeof(T))
			if new_ptr != null {
				self.ptr = new_ptr
				self.size = count * @sizeof(T)
			}
			return @bitcast(new_ptr)
		}
	}
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if target == target_c_native {
			target.free(self.ptr)
		} else if target == target_hbvm_ableos {
			target.free(self.ptr, self.size)
		}
	}
}