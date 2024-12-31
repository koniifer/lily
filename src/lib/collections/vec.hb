.{target, target_c_native, target_hbvm_ableos, result: .{Result}} := @use("../lib.hb");
.{Error} := @use("lib.hb")

Vec := fn($T: type, $A: type): type return struct {
	slice: []T,
	allocator: ^A,
	cap: uint,

	$new := fn(allocator: ^A): Self return .{slice: T.[][..], allocator, cap: 0}
	deinit := fn(self: ^Self): void {
		if self.slice.len != 0 {
			self.allocator.free(T, self.slice.ptr)
		};
		*self = Self.new(self.allocator)
	}
	push := fn(self: ^Self, value: T): void {
		if self.slice.len == self.cap {
			if self.cap == 0 {
				self.cap = 1
			} else {
				self.cap *= 2
			}

			// ! (compiler?) bug: null check broken, so unwrapping (unsafe!)
			new_alloc := @unwrap(self.allocator.alloc(T, self.cap))

			if self.slice.len != 0 {
				target.memmove(@bitcast(new_alloc), @bitcast(self.slice.ptr), self.slice.len * @sizeof(T))
				self.allocator.free(T, self.slice.ptr)
			}
			self.slice.ptr = @as(^T, new_alloc)
		};
		self.slice[self.slice.len] = value
		self.slice.len += 1
	}
	get := fn(self: ^Self, n: uint): Result(T, Error) {
		if n >= self.slice.len return Result(T, Error).err(.OutOfRange)
		return Result(T, Error).ok(self.slice[n])
	}
	get_ref := fn(self: ^Self, n: uint): Result(^T, Error) {
		if n >= self.slice.len return Result(T, Error).err(.OutOfRange)
		return Result(T, Error).ok(self.slice.ptr + n)
	}
	$get_unchecked := fn(self: ^Self, n: uint): T return self.slice[n]
	$get_ref_unchecked := fn(self: ^Self, n: uint): T return self.slice.ptr + n
	pop := fn(self: ^Self): Result(T, Error) {
		if self.slice.len == 0 return Result(T, Error).err(.OutOfRange)
		temp := self.slice[self.slice.len - 1]
		self.slice = self.slice[..self.slice.len - 1]
		return Result(T, Error).ok(temp)
	}
	$len := fn(self: ^Self): uint return self.slice.len
	$capacity := fn(self: ^Self): uint return self.cap
}