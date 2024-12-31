.{collections: .{Vec}, target, target_c_native, target_hbvm_ableos} := @use("lib.hb")

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
		i := 0
		loop if i == self.allocations.len() break else {
			defer i += 1
			alloced := self.allocations.get_unchecked(i)
			if target == target_c_native {
				target.free(alloced.ptr)
			} else if target == target_hbvm_ableos {
				target.free(alloced.ptr, alloced.len)
			}
		}
		self.allocations.deinit();
		*self = Self.new()
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := target.malloc(count * @sizeof(T))
		// ! (compiler?) bug: null check broken, so unwrapping (unsafe!)
		if target == target_hbvm_ableos {
			self.allocations.push(.(@unwrap(ptr), count))
		}
		return @bitcast(ptr)
	}
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if target == target_c_native {
			target.free(@bitcast(ptr))
		} else if target == target_hbvm_ableos {
			alloced := self._find(@bitcast(ptr))
			if alloced == null return;
			target.free(@bitcast(ptr), alloced.len)
		}
	}
	_find := fn(self: ^Self, ptr: ^void): ?Allocation {
		i := 0
		loop if i == self.allocations.len() break else {
			defer i += 1
			result := self.allocations.get(i)
			if !result.is_ok return null
			alloced := result.unwrap_unchecked()
			if alloced.ptr == ptr return alloced
		}
		return null
	}
}

// ! THIS ALLOCATOR IS *ALSO* TEMPORARY
RawAllocator := struct {
	ptr: ^void,
	size: uint,
	$new := fn(): Self return .(@bitcast(0), 0)
	deinit := fn(self: ^Self): void {
		if self.size != 0 {
			if target == target_c_native {
				target.free(@bitcast(self.ptr))
			} else if target == target_hbvm_ableos {
				target.free(@bitcast(self.ptr), self.size)
			}
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
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if target == target_c_native {
			target.free(@bitcast(self.ptr))
		} else if target == target_hbvm_ableos {
			target.free(@bitcast(self.ptr), self.size)
		}
	}
}