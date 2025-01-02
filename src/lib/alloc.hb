.{collections: .{Vec}, target, target_c_native, target_hbvm_ableos, null_pointer} := @use("lib.hb")

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
		loop if self.allocations.len == 0 break else {
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
			if ptr != null {
				self.allocations.push(.(ptr, count * @sizeof(T)))
			}
		}
		return @bitcast(ptr)
	}
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if target == target_c_native {
			target.free(@bitcast(ptr))
		} else if target == target_hbvm_ableos {
			alloced := self._find_and_remove(@bitcast(ptr))
			if alloced == null return;
			target.free(@bitcast(ptr), alloced.len)
		}
	}
	_find_and_remove := fn(self: ^Self, ptr: ^void): ?Allocation {
		i := 0
		loop if i == self.allocations.len break else {
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
	old_ptr: ^void,
	size: uint,
	old_size: uint,
	$new := fn(): Self return .(null_pointer(void), null_pointer(void), 0, 0)
	deinit := fn(self: ^Self): void {
		if target == target_c_native {
			target.free(self.ptr)
			target.free(self.old_ptr)
		} else if target == target_hbvm_ableos {
			target.free(self.ptr, self.size)
			target.free(self.old_ptr, self.old_size)
		};
		*self = Self.new()
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := target.malloc(count * @sizeof(T))
		if ptr != null {
			self.old_ptr = self.ptr
			self.old_size = self.size
			self.ptr = ptr
			self.size = count * @sizeof(T)
		}
		return @bitcast(ptr)
	}
	free := fn(self: ^Self, $T: type, ptr: ^T): void {
		if target == target_c_native {
			target.free(self.old_ptr)
		} else if target == target_hbvm_ableos {
			target.free(self.old_ptr, self.old_size)
		}
	}
}