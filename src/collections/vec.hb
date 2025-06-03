lily.{panic, config, log, mem} := @use("../lib.hb")

Vec := fn(T: type, A: type): type return struct {
	.slice: []T;
	.cap: uint;
	.allocator: ^A

	Self := @CurrentScope()

	$new := fn(allocator: ^A): Self {
		return .(&.[], 0, allocator)
	}
	new_with_capacity := fn(allocator: ^A, cap: uint): Self {
		new_alloc := allocator.alloc(T, cap)
		if new_alloc == null {
			// todo: handle
			die
		}
		return .(new_alloc.?[..0], cap, allocator)
	}
	$fill_end_with := fn(self: ^Self, elem: ^T): void {
		self.slice.len = self.cap
		mem.fill(mem.as_bytes(self.slice[self.slice.len..]), mem.as_bytes(elem))
	}
	$fill_with := fn(self: ^Self, elem: ^T): void {
		self.slice.len = self.cap
		mem.fill(mem.as_bytes(self.slice), mem.as_bytes(elem))
	}
	$deinit := fn(self: ^Self): void {
		$if @compiles(T.deinit) {
			i := 0
			loop if i == self.slice.len break else {
				_ = self.slice[i].deinit()
				i += 1
			}
		}
		self.allocator.dealloc(T, self.slice[0..self.cap])
		self.* = idk
	}
	reserve := fn(self: ^Self, n: uint): void {
		if n <= self.cap {
			log.debug("Vec: useless reserve, n <= self.cap")
			return
		}
		// todo: next power of two
		new_alloc := self.allocator.realloc(T, self.slice[..self.cap], n)

		if new_alloc == null {
			// todo: handle
			die
		}

		self.cap = n
		self.slice.ptr = new_alloc.?.ptr
	}
	push := fn(self: ^Self, elem: T): void {
		if self.slice.len == self.cap {
			if self.cap == 0 {
				new_slice := self.allocator.alloc(T, 1)
				if new_slice == null {
					// todo: handle
					die
				}
				self.slice.ptr = new_slice.?.ptr
				self.cap = new_slice.?.len
			} else {
				new_slice := self.allocator.realloc(T, self.slice[0..self.cap], self.cap * 2)
				if new_slice == null {
					// todo: handle
					die
				}
				self.slice.ptr = new_slice.?.ptr
				self.cap = new_slice.?.len
			}
		}
		self.slice[self.slice.len] = elem
		self.slice.len += 1
	}
	get := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		return self.get_unchecked(n)
	}
	$get_unchecked := fn(self: ^Self, n: uint): T return self.slice[n]
	set := fn(self: ^Self, n: uint, elem: T): void {
		if n >= self.slice.len return null
		self.set_unchecked(n, elem)
	}
	$set_unchecked := fn(self: ^Self, n: uint, elem: T): void self.slice[n] = elem
	get_ref := fn(self: ^Self, n: uint): ?^T {
		if n >= self.slice.len return null
		return self.get_ref_unchecked(n)
	}
	$get_ref_unchecked := fn(self: ^Self, n: uint): ^T return self.slice.ptr + n
	pop := fn(self: ^Self): ?T {
		if self.slice.len == 0 return null
		return self.pop_unchecked()
	}
	$pop_unchecked := fn(self: ^Self): T {
		self.slice.len -= 1
		return self.slice[self.slice.len]
	}
	// todo: unchecked variants when?
	remove := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		if n + 1 == self.slice.len return self.pop_unchecked()
		temp := self.slice[n]
		// todo: reduce need for as_bytes
		mem.move(mem.as_bytes(self.slice[n..]), mem.as_bytes(self.slice[n + 1..]))
		self.slice.len -= 1
		return temp
	}
	swap_remove := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		if n + 1 == self.slice.len return self.pop_unchecked()
		temp := self.slice[n]
		self.slice[n] = self.pop_unchecked()
		return temp
	}
	$len := fn(self: ^Self): uint {
		return self.slice.len
	}
	$_fmt := fn(self: ^Self, buf: []u8): uint {
		return lily.fmt.fmt_container(buf, self.slice)
	}
}
