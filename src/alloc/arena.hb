lily.{target, mem} := @use("../lib.hb")

AllocationHeader := struct {
	.cap: uint;
	.len: uint;
	.next: ?^AllocationHeader

	new := fn(size: uint): ?^AllocationHeader {
		total_size := size + @size_of(AllocationHeader)
		ptr: ?^AllocationHeader = @bit_cast(target.alloc(total_size))
		if ptr == null return null
		header: ^AllocationHeader = @bit_cast(ptr)
		header.* = .(
			target.pages(total_size) * target.page_len() - @size_of(AllocationHeader),
			0,
			null,
		)
		return header
	}
}

Arena := struct {
	.allocation: ?^AllocationHeader

	$new := fn(): @CurrentScope() {
		return .(null)
	}
	// todo: handle alignment
	alloc := fn(self: ^Arena, $T: type, count: uint): ?[]T {
		size := mem.size(T, count)
		header: ^AllocationHeader = idk
		if self.allocation == null {
			new_header := AllocationHeader.new(size)
			// todo: handle cleanly
			if new_header == null die
			self.allocation = new_header
			header = @bit_cast(new_header)
		} else {
			header = @bit_cast(self.allocation)
		}

		loop {
			if header.len + size <= header.cap {
				header.len += size
				break
			}
			if header.next == null {
				header.next = AllocationHeader.new(size)
			}
			header = @bit_cast(header.next)
		}
		return @as(^T, @bit_cast(@as(^u8, @bit_cast(header + 1)) + header.len - size))[0..count]
	}
	deinit := fn(self: ^Arena): void {
		if self.allocation == null {
			lily.log.error("fixme: double free arena. can't fix due to compiler.")
			die
		}
		allocation: ^AllocationHeader = @bit_cast(self.allocation)
		loop {
			next := allocation.next
			target.dealloc(@bit_cast(allocation), allocation.cap)
			if next == null break
			allocation = @bit_cast(next)
		}
		self.allocation = null
	}
}
