.{memmove, Type, log, alloc, quicksort, compare, iter} := @use("../lib.hb");

Vec := fn($T: type, $Allocator: type): type return struct {
	slice: []T,
	allocator: ^Allocator,
	cap: uint = 0,
	$new := fn(allocator: ^Allocator): Self return .{slice: Type([]T).uninit(), allocator}
	$with_capacity := fn(allocator: ^Allocator, cap: uint): Self {
		// ! (libc) (compiler) bug: null check broken, so unwrapping (unsafe!)
		new_alloc := @unwrap(allocator.alloc(T, cap))
		return .{slice: new_alloc[0..0], allocator, cap}
	}
	deinit := fn(self: ^Self): void {
		// currently does not handle deinit of T if T allocates memory
		if self.cap > 0 self.allocator.dealloc(T, self.slice.ptr)
		self.slice = Type([]T).uninit()
		self.cap = 0
		if Allocator == alloc.RawAllocator {
			log.debug("deinit: vec (w/ raw allocator)")
		} else {
			log.debug("deinit: vec")
		}
	}
	// todo: maybe make this exponential instead
	reserve := fn(self: ^Self, n: uint): void {
		if self.len() + n <= self.cap return;
		// ! (libc) (compiler) bug: null check broken, so unwrapping (unsafe!)
		new_alloc := @unwrap(self.allocator.realloc(T, self.slice.ptr, self.cap + n))
		self.cap += n
		self.slice.ptr = new_alloc
	}
	push := fn(self: ^Self, value: T): void {
		if self.slice.len == self.cap {
			if self.cap == 0 {
				// ! (libc) (compiler) bug: null check broken, so unwrapping (unsafe!)
				new_alloc := @unwrap(self.allocator.alloc(T, 1))
				self.slice.ptr = new_alloc
				self.cap = 1
			} else {
				// ! (libc) (compiler) bug: null check broken, so unwrapping (unsafe!)
				new_alloc := @unwrap(self.allocator.realloc(T, self.slice.ptr, self.cap * 2))
				self.slice.ptr = new_alloc
				self.cap *= 2
			}
		}
		self.slice[self.slice.len] = value
		self.slice.len += 1
	}
	get := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		return self.slice[n]
	}
	$get_unchecked := fn(self: ^Self, n: uint): T return self.slice[n]
	get_ref := fn(self: ^Self, n: uint): ?^T {
		if n >= self.slice.len return null
		return self.slice.ptr + n
	}
	$get_ref_unchecked := fn(self: ^Self, n: uint): ^T return self.slice.ptr + n
	pop := fn(self: ^Self): ?T {
		if self.slice.len == 0 return null
		self.slice.len -= 1
		// as far as im aware this is not undefined behaviour.
		return self.slice[self.slice.len]
	}
	$pop_unchecked := fn(self: ^Self): T {
		self.slice.len -= 1
		// as far as im aware this is not undefined behaviour. (2)
		return self.slice[self.slice.len]
	}
	remove := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		if n + 1 == self.slice.len return self.pop_unchecked()
		temp := self.slice[n]
		memmove(self.slice.ptr + n, self.slice.ptr + n + 1, (self.slice.len - n - 1) * @sizeof(T))
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
	find := fn(self: ^Self, rhs: T): ?uint {
		i := 0
		loop if self.get_unchecked(i) == rhs return i else if i == self.slice.len return null else i += 1
	}
	$sort_with := fn(self: ^Self, $func: type): void {
		_ = quicksort(func, self.slice, 0, self.slice.len - 1)
	}
	$sort := fn(self: ^Self): void self.sort_with(compare)
	$len := fn(self: ^Self): uint return self.slice.len
	$capacity := fn(self: ^Self): uint return self.cap
}