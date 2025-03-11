lily.{target, mem} := @use("../lib.hb")

AllocationHeader := struct {
	.cap: uint;
	.len: uint;
	.next: ?^Self

	Self := @CurrentScope()

	$new := fn(size: uint): ?^Self {
		total_size := size + @size_of(Self)
		ptr: ?^Self = @bit_cast(target.alloc(total_size))
		if ptr == null return null
		header: ^Self = @bit_cast(ptr)
		header.* = .(
			target.pages(total_size) * target.page_len() - @size_of(Self),
			0,
			null,
		)
		return header
	}
}

Arena := struct {
	.allocation: ?^AllocationHeader

	Self := @CurrentScope()

	$new := fn(): Self {
		return .(null)
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?[]T {
		size := mem.size(T, count)
		header: ^AllocationHeader = @bit_cast(self.allocation)

		if self.allocation == null {
			new_header := AllocationHeader.new(size)
			// todo: handle cleanly
			if new_header == null die
			self.allocation = new_header
			header = @bit_cast(new_header)
		}

		loop {
			lily.log.debug("arena.hb:45: if i dont print this it crashes")
			if header.len + size <= header.cap {
				header.len += size
				break
			}
			if header.next == null {
				header.next = AllocationHeader.new(size)
				// todo: handle cleanly
				if header.next == null die
			}
			header = @bit_cast(header.next)
		}
		return @as(^T, @bit_cast(@as(^u8, @bit_cast(header + 1)) + header.len - size))[0..count]
	}
	$alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?[]T {
		slice := self.alloc(T, count)
		if slice == null return null
		mem.set(slice.?.ptr, 0, slice.?.len)
		return slice
	}
	$realloc := fn(self: ^Self, $T: type, prev: []T, count_new: uint): ?[]T {
		slice := self.alloc(T, mem.size(T, count_new))
		if slice == null return null
		mem.copy(@bit_cast(slice.?.ptr), @bit_cast(prev.ptr), mem.size(T, prev.len))
		return slice
	}
	$dealloc := fn(self: ^Self, $T: type, prev: []T): void {
	}
	deinit := fn(self: ^Self): void {
		if self.allocation == null {
			lily.log.error("fixme: double free arena. can't fix due to compiler.")
			die
		}
		allocation: ^AllocationHeader = @bit_cast(self.allocation)
		loop {
			next := allocation.next
			target.dealloc(@bit_cast(allocation), allocation.cap + @size_of(AllocationHeader))
			if next == null break
			allocation = @bit_cast(next)
		}
		self.allocation = null
	}
}
