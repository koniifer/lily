.{target, target_c_native, target_hbvm_ableos, memmove, Type} := @use("../lib.hb");

SparseVec := fn($T: type, $A: type): type return struct {
	// slice.len tracks null and non-null elements
	slice: []?T,
	allocator: ^A,
	// len tracks non-null elements
	len: uint,
	// capacity tracks maximum slice.len before reallocating
	capacity: uint,

	$new := fn(allocator: ^A): Self return .{slice: Type([]?T).uninit(), allocator, capacity: 0, len: 0}
	deinit := fn(self: ^Self): void {
		// currently does not handle deinit of T if T allocates memory
		if self.capacity != 0 self.allocator.free(?T, self.slice.ptr)
		self.slice = Type([]?T).uninit()
		self.capacity = 0
	}
	push := fn(self: ^Self, value: T): void {
		if self.slice.len == self.capacity {
			if self.capacity == 0 {
				self.capacity = 1
			} else {
				self.capacity *= 2
			}

			// ! (c_native) (compiler) bug: null check broken, so unwrapping (unsafe!)
			new_alloc := @unwrap(self.allocator.alloc(?T, self.capacity))

			if self.len > 0 {
				memmove(new_alloc, self.slice.ptr, self.slice.len * @sizeof(?T))
			}

			if self.slice.len > 0 {
				self.allocator.free(?T, self.slice.ptr)
			}
			self.slice.ptr = new_alloc
		}
		self.slice[self.slice.len] = value
		self.slice.len += 1
		self.len += 1
	}
	get := fn(self: ^Self, n: uint): ?T {
		m := 0
		j := 0
		loop if m == self.slice.len return null else {
			a := self.slice[m]
			if a != null {
				if j == n return a
				j += 1
			}
			m += 1
		}
	}
	pop := fn(self: ^Self): ?T {
		if self.len == 0 return null
		n := self.slice.len - 1
		loop if n == 0 return null else {
			a := self.slice[n]
			if a != null {
				self.slice[n] = null
				self.slice.len -= 1
				self.len -= 1
				return a
			}
			n -= 1
		}
	}
	remove := fn(self: ^Self, n: uint): ?T {
		if self.len == 0 return null
		m := 0
		j := 0
		loop if m == self.slice.len return null else {
			a := self.slice[m]
			if a != null {
				// ! (compiler) bug: This print causes compiler panic
				if !@target("*-virt-unknown") printf("%d\n\0".ptr, a)
				if j == n {
					self.slice[m] = null
					self.len -= 1
					// ! (compiler) bug: This print happens but we never see the "zub zub" in main.hb
					if !@target("*-virt-unknown") printf("here: %d\n\0".ptr, a)
					return a
				}
				j += 1
			}
			m += 1
		}
	}
}

printf := fn(str: ^u8, u: uint): void @import()