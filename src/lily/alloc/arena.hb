.{Config, Type, Target, log, collections: .{Vec}, alloc: .{RawAllocator}, math} := @use("../lib.hb");

$next_power_of_two := fn(n: uint): uint {
	n -= 1
	n |= n >> 1
	n |= n >> 2
	n |= n >> 4
	n |= n >> 8
	n |= n >> 16
	n |= n >> 32
	return n + 1
}

$compute_align := fn(size: uint, align: uint): uint {
	return size + align - 1 & 1 << @sizeof(uint) * 8 - (align - 1)
}

$fit_pages := fn(size: uint): uint {
	return Target.calculate_pages(size) * Target.page_size()
}

$alloc_size := fn(size: uint): uint {
	return fit_pages(math.max(next_power_of_two(size), 1))
}

ArenaAllocator := struct {
	blocks: Vec([]u8, RawAllocator),
	current_block: []u8,
	offset: uint,
	last_alloc_start: uint,
	last_alloc_size: uint,
	raw: RawAllocator,

	$new := fn(): Self {
		raw := RawAllocator.new()
		blocks := Vec([]u8, RawAllocator).new(&raw)
		return .(blocks, Type([]u8).uninit(), 0, 0, 0, raw)
	}
	deinit := fn(self: ^Self): void {
		loop if self.blocks.len() == 0 break else {
			block := self.blocks.pop_unchecked()
			Target.dealloc(block.ptr, block.len)
		}
		self.blocks.deinit()
		self.raw.deinit();
		self.current_block = Type([]u8).uninit()
		self.offset = 0
		self.last_alloc_start = 0
		self.last_alloc_size = 0
		log.debug("deinit: arena allocator")
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?[]T {
		size := @sizeof(T) * count
		if Config.debug_assertions() & size == 0 {
			log.error("arena: zero sized allocation")
			return null
		}
		aligned := compute_align(self.offset, @alignof(T))
		new_space := aligned + size
		if new_space > self.current_block.len {
			new_size := alloc_size(size)
			// ! (libc) (compiler) bug: null check broken. unwrapping.
			new_ptr := @unwrap(Target.alloc_zeroed(new_size))
			new_block := new_ptr[0..new_size]
			self.blocks.push(new_block)
			self.current_block = new_block
			self.offset = 0
			aligned = 0
		}
		ptr := self.current_block.ptr + aligned
		self.last_alloc_start = aligned
		self.last_alloc_size = size
		self.offset = aligned + size
		log.debug("arena: allocated")
		return @as(^T, @bitcast(ptr))[0..count]
	}
	alloc_zeroed := Self.alloc
	realloc := fn(self: ^Self, $T: type, ptr: ^T, new_count: uint): ?[]T {
		r0 := @as(^u8, @bitcast(ptr)) != self.current_block.ptr + self.last_alloc_start
		r1 := self.last_alloc_start + self.last_alloc_size != self.offset
		// ! (libc) (compiler) bug: checking r0 | r1 here gives "not yet implemented: bool"
		if Target.current() != .LibC if r0 | r1 {
			if Config.debug_assertions() {
				log.error("arena: realloc only supports last allocation")
			}
			return null
		}
		size := @sizeof(T) * new_count
		if size <= self.last_alloc_size {
			if Config.debug_assertions() {
				log.warn("arena: useless reallocation (new_size <= old_size)")
			}
			return ptr[0..new_count]
		}
		additional := size - self.last_alloc_size
		if self.offset + additional <= self.current_block.len {
			self.offset += additional
			self.last_alloc_size = size
			return ptr[0..new_count]
		}
		new_size := alloc_size(size)
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		new_ptr := @unwrap(Target.alloc_zeroed(new_size))
		new_block := new_ptr[0..new_size]
		Target.memcopy(new_ptr, @bitcast(ptr), self.last_alloc_size)
		self.blocks.push(new_block)
		self.current_block = new_block
		self.offset = size
		self.last_alloc_start = 0
		self.last_alloc_size = size
		log.debug("arena: reallocated")
		return @as(^T, @bitcast(new_ptr))[0..new_count]
	}
	$dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		if Config.debug_assertions() log.error("arena: dealloc called. (makes no sense)")
	}
}