.{target, target_c_native, target_hbvm_ableos, result: .{Result}, null_pointer} := @use("../lib.hb");
.{Error} := @use("lib.hb")

Vec := fn($T: type, $A: type): type return struct {
	// self.slice.len tracks non-null elements
	slice: []?T,
	allocator: ^A,
	len: uint,
	capacity: uint,

	$new := fn(allocator: ^A): Self return .{slice: null_pointer(?T)[0..0], allocator, capacity: 0, len: 0}
	deinit := fn(self: ^Self): void {
		// currently does not handle deinit of T if T allocates memory
		if self.capacity != 0 self.allocator.free(?T, self.slice.ptr)
		self.slice = null_pointer(?T)[0..0]
		self.capacity = 0
	}
	push := fn(self: ^Self, value: T): void {
		if self.slice.len == self.capacity {
			if self.capacity == 0 {
				self.capacity = 1
			} else {
				self.capacity *= 2
			}

			// ! (compiler?) bug: null check broken, so unwrapping (unsafe!)
			new_alloc := @unwrap(self.allocator.alloc(?T, self.capacity))

			if self.slice.len > 0 {
				target.memmove(@bitcast(new_alloc), @bitcast(self.slice.ptr), self.slice.len * @sizeof(?T))
				self.allocator.free(?T, self.slice.ptr)
			}
			self.slice.ptr = new_alloc
		}
		self.slice[self.slice.len] = value
		self.slice.len += 1
		self.len += 1
	}
	get := fn(self: ^Self, n: uint): ?T {
		loop if n >= self.len return null else {
			a := self.slice[n]
			if a != null return a
			n += 1
		}
	}
	pop := fn(self: ^Self): ?T {
		if self.len == 0 return null
		n := self.slice.len - 1
		loop {
			a := self.slice[n]
			if a != null {
				self.slice.len -= 1
				self.len -= 1
				return a
			}
			n -= 1
		}
	}
	remove := fn(self: ^Self, n: uint): ?T {
		loop if n >= self.len return null else {
			a := self.slice[n]
			if a != null {
				self.slice[n] = null
				self.len -= 1
				return a
			}
			n += 1
		}
	}
}