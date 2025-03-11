Vec := fn(T: type, A: type): type return struct {
	.slice: []T;
	.cap: uint;
	.allocator: ^A

	Self := @CurrentScope()

	$new := fn(allocator: ^A): Self {
		return .(idk, 0, allocator)
	}
	push := fn(self: ^Self, elem: T): void {
		if self.slice.len == self.cap {
			if self.cap == 0 {
				new_slice := self.allocator.alloc(T, 1)
				if new_slice == null {
					// todo: handle
					die
				}
				self.slice = new_slice.?[0..self.slice.len]
				self.cap = new_slice.?.len
			} else {
				new_slice := self.allocator.realloc(T, self.slice[0..self.cap], self.cap * 2)
				if new_slice == null {
					// todo: handle
					die
				}
				self.slice = new_slice.?[0..self.slice.len]
				self.cap = new_slice.?.len
			}
		}
		self.slice[self.slice.len] = elem
		self.slice = self.slice[0..self.slice.len + 1]
	}

	$len := fn(self: ^Self): uint {
		return self.slice.len
	}

	deinit := fn(self: ^Self): void {
		self.allocator.dealloc(T, self.slice[0..self.cap])
		self.* = idk
	}
}
