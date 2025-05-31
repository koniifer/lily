lily.{target, mem, config} := @use("../lib.hb")

AllocationHeader := struct {
	.cap: uint;
	.len: uint;
	.next: ?^@CurrentScope()

	$new := fn(size: uint): ?^@CurrentScope() {
		total_size := size + @size_of(@CurrentScope())
		ptr: ?^u8 = target.alloc(total_size)
		if ptr == null return null
		header: ^@CurrentScope() = @bit_cast(ptr.?)
		header.* = .(
			target.pages(total_size) * target.page_len() - @size_of(@CurrentScope()),
			0,
			null,
		)
		return header
	}
};

.allocation: ?^AllocationHeader

Self := @CurrentScope()

$new := fn(): Self {
	return .(null)
}
alloc := fn(self: ^Self, $T: type, count: uint): ?[]T {
	size := mem.size(T, count)

	if size == 0 return null

	header: ^AllocationHeader = @bit_cast(self.allocation)

	if self.allocation == null {
		new_header := AllocationHeader.new(size)
		if new_header == null return null

		self.allocation = new_header
		header = new_header.?
	}

	loop {
		base_ptr: ^u8 = @bit_cast(header + 1)
		current_ptr := base_ptr + header.len
		aligned_ptr := mem.forward_align(current_ptr, @align_of(T))
		padding: uint = @bit_cast(aligned_ptr - current_ptr)

		required_size := padding + size
		if header.len + required_size <= header.cap {
			header.len += required_size
			return @as(^T, @bit_cast(aligned_ptr))[0..count]
		}
		if header.next == null {
			header.next = AllocationHeader.new(size)
			if header.next == null return null
		}
		header = header.next.?
	}
}
$alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?[]T {
	slice := self.alloc(T, count)
	if slice == null return null
	mem.set(mem.as_bytes(slice.?), 0)
	return slice
}
$realloc := fn(self: ^Self, $T: type, prev: []T, count_new: uint): ?[]T {
	slice := self.alloc(T, count_new)
	if slice == null return null
	mem.copy(mem.as_bytes(slice.?), mem.as_bytes(prev))
	return slice
}
$dealloc := fn(self: ^Self, $T: type, prev: []T): void {
}
deinit := fn(self: ^Self): void {
	if self.allocation == null {
		return
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
