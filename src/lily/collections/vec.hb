.{memmove, Type, log, alloc, quicksort, compare, iter} := @use("../lib.hb");

Vec := fn($T: type, $Allocator: type): type return struct {
	slice: []T,
	allocator: ^Allocator,
	cap: uint,
	$new := fn(allocator: ^Allocator): Self return .{slice: Type([]T).uninit(), allocator, cap: 0}
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
	push := fn(self: ^Self, value: T): void {
		if self.slice.len == self.cap {
			if self.cap == 0 {
				self.cap = 1
				new_alloc := @unwrap(self.allocator.alloc(T, self.cap))
				self.slice.ptr = new_alloc
			} else {
				self.cap *= 2
				// ! (libc) (compiler) bug: null check broken, so unwrapping (unsafe!)
				new_alloc := @unwrap(self.allocator.realloc(T, self.slice.ptr, self.cap))
				self.slice.ptr = new_alloc
			}
		}
		self.slice[self.slice.len] = value
		self.slice.len += 1
	}
	get := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		return self.slice[n]
	}
	get_ref := fn(self: ^Self, n: uint): ?^T {
		if n >= self.slice.len return null
		return self.slice.ptr + n
	}
	pop := fn(self: ^Self): ?T {
		if self.slice.len == 0 return null
		self.slice.len -= 1
		return self.slice[self.slice.len]
	}
	remove := fn(self: ^Self, n: uint): ?T {
		if n >= self.slice.len return null
		if n + 1 == self.slice.len return self.pop()
		temp := self.slice[n]
		memmove(self.slice.ptr + n, self.slice.ptr + n + 1, (self.slice.len - n - 1) * @sizeof(T))
		self.slice.len -= 1
		return temp
	}
	find := fn(self: ^Self, rhs: T): ?uint {
		i := 0
		loop if self.get(i) == rhs return i else if i == self.slice.len return null else i += 1
	}
	$into_iter := fn(self: Self): iter.Iterator(iter.SliceIter(T)) {
		return .(.(self.slice, 0))
	}
	$sort := fn(self: ^Self): void {
		_ = quicksort(compare, self.slice, 0, self.slice.len - 1)
	}
	$sort_with := fn(self: ^Self, $func: type): void {
		_ = quicksort(func, self.slice, 0, self.slice.len - 1)
	}
	$len := fn(self: ^Self): uint return self.slice.len
	$capacity := fn(self: ^Self): uint return self.capacity
}