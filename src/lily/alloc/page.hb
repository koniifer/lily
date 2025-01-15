.{Config, Target, Type, TypeOf, log, collections: .{Vec}, quicksort} := @use("../lib.hb");
.{RawAllocator} := @use("lib.hb")

/*
 * intended behaviour: (may not be complete)
 * alloc:
 * -> if no pages, or all pages full: allocate new pages enough for next allocation.
 * -> for first page with contiguous space enough for next allocation, allocate there.
 * dealloc: 
 * -> requires:
 *    -> ptr must be the first ptr of the allocation
 *    -> ptr must be in allocation table
 * -> remove allocation from allocation table
 * -> recalculate contiguous free space in page it was contained in
 * -> if page is empty, free page
 * realloc:
 * -> if new size == original size: do nothing
 * -> if new size requires any new page(s) to be allocated, use Target.realloc() to get new pointer
 * -> else, Self.dealloc, Self.alloc, memmove
 
 * design todo:
 * -> better perf to Self.alloc, memcopy, Self.dealloc?
 * -> security would prefer zeroing deallocations before freeing (would require the new order above) (maybe make it a build toggle)
 * -> swap Vec(T, RawAllocator) for internal tables (for efficiency)

 * assumptions:
 * -> pages are of a constant length (per system)

 ! IMPORTANT
 ! to ensure referential integrity, we do not move the contents of the blocks to new blocks
 !   (except when reallocating)
 */

Block := struct {
	block: []u8,
	largest_free: []u8,
}

// i cannot pretend this is efficient. (also incomplete)

PageAllocator := struct {
	blocks: Vec(Block, RawAllocator),
	allocs: Vec([]u8, RawAllocator),
	blocks_raw: RawAllocator,
	allocs_raw: RawAllocator,

	new := fn(): Self {
		blocks_raw := RawAllocator.new()
		allocs_raw := RawAllocator.new()
		blocks := Vec(Block, RawAllocator).new(&blocks_raw)
		allocs := Vec([]u8, RawAllocator).new(TypeOf(&allocs_raw).uninit())
		self := Self.(
			blocks,
			allocs,
			blocks_raw,
			allocs_raw,
		)
		self.blocks.allocator = &self.blocks_raw
		self.allocs.allocator = &self.allocs_raw
		return self
	}
	deinit := fn(self: ^Self): void {
		self.allocs.deinit()
		loop if self.blocks.len() == 0 break else {
			// ! (compiler) bug: not logging here causes double free or corruption... wtf...
			log.debug("here")
			block := @unwrap(self.blocks.pop())
			match Target.current() {
				.AbleOS => Target.dealloc(block.block.ptr, block.block.len),
				.LibC => Target.dealloc(block.block.ptr),
			}
		}
		self.blocks.deinit()
		self.blocks_raw.deinit()
		self.allocs_raw.deinit()
	}
	alloc := fn(self: ^Self, $T: type, count: uint): ?^T {
		This := Type(T)
		size := This.size() * count
		i := 0
		loop if i >= self.blocks.len() break else {
			defer i += 1
			block := @unwrap(self.blocks.get_ref(i))
			if block.largest_free.len >= size {
				ptr := self._update_block(block, size)
				self.allocs.push(ptr[0..size])
				return @bitcast(ptr)
			}
		}
		block_size := Target.calculate_pages(size) * Target.page_size()
		// ! (libc) (compiler) bug: null check broken. unwrapping.
		block_ptr := @unwrap(Target.alloc(block_size))
		block := Block.(block_ptr[0..block_size], block_ptr[size..block_size])
		// ! (libc) (compiler) wtf bug is this? can't push anything to blocks...
		self.blocks.push(block)
		self.allocs.push(block_ptr[0..size])
		log.debug("pushed to allocs")
		log.print(size)
		log.print(block_size)
		return @bitcast(block_ptr + size)
	}
	alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?^T {
		ptr := Self.alloc_zeroed(T, count)
		if ptr == null return null
		Target.memset(ptr, 0, count * @sizeof(T))
		return ptr
	}
	realloc := fn(self: ^Self, $T: type, ptr: ^T, new_count: uint): ?^T {
		log.error("todo: realloc")
		die
		return null
	}
	dealloc := fn(self: ^Self, $T: type, ptr: ^T): void {
		log.error("todo: dealloc")
		die
	}

	/// SAFETY: assumes that the block has enough space for `size`
	_update_block := fn(self: ^Self, block: ^Block, size: uint): ^u8 {
		block.largest_free = block.largest_free[0..size]
		ptr := block.largest_free.ptr

		// _ = quicksort(_compare_ptr, self.allocs.slice, 0, self.allocs.len() - 1)
		self.allocs.sort_with(_compare_ptr)
		log.print(self.allocs.slice)

		i := 0
		loop if i == self.allocs.len() - 1 break else {
			defer i += 1
			alloc_a := @unwrap(self.allocs.get_ref(i))
			if alloc_a.ptr < block.block.ptr {
				i += 1
				continue
			} else if alloc_a.ptr > block.block.ptr + block.block.len {
				break
			}

			len: uint = 0
			alloc_b := @unwrap(self.allocs.get_ref(i + 1))
			pt2 := alloc_a.ptr + alloc_a.size
			if alloc_b.ptr > block.block.ptr {
				len = block.block.ptr + block.block.len - pt2
			} else {
				len = alloc_b.ptr - pt2
			}
			if len > block.largest_free.len {
				block.largest_free = (*alloc_a)[0..len]
			}
			log.debug("here 2")
		}
		return ptr
	}
}

$_compare_ptr := fn(lhs: @Any(), rhs: @Any()): bool {
	return lhs.ptr < rhs.ptr
}