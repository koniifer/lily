lily.{iter, TypeInfo, log, mem, target, math} := @use("../lib.hb")

Entry := fn($K: type, $V: type): type return struct {
	.key: K;
	.value: V

	$_fmt := fn(self: ^@CurrentScope(), buf: []u8): uint {
		return lily.fmt.format(buf, .(self.key, self.value))
	}
}

$vacant: u8 = 0xFF
$tombstone: u8 = 0x80

HashMap := fn($K: type, $V: type, $A: type, $H: type): type return struct {
	.metadata: ^u8;
	.entries: []Entry(K, V);
	.hasher: H;
	.allocator: ^A;
	.size: uint;
	.tombstones: uint

	Self := @CurrentScope()

	$new := fn(allocator: ^A): Self {
		entries := allocator.alloc(Entry(K, V), 32).?
		metadata := allocator.alloc(u8, 32).?.ptr
		mem.set(metadata[0..entries.len], vacant)
		// return .(metadata, entries, .default(), allocator, 0, 0)
		// temporarily fix seed for testing purposes
		return .(metadata, entries, .new((1 << 32) - 1), allocator, 0, 0)
	}
	$deinit := fn(self: ^Self): void {
		self.allocator.dealloc(u8, self.metadata[0..self.entries.len])
		self.allocator.dealloc(Entry(K, V), self.entries)
		self.hasher.deinit()
		self.* = idk
	}
	$hash_key := fn(self: ^Self, key: K): uint {
		self.hasher.reset()
		self.hasher.write(key)
		return self.hasher.finish()
	}
	_rehash := fn(self: ^Self): void {
		old_entries := self.entries
		old_metadata := self.metadata

		prev_len := old_entries.len
		new_len := prev_len * 2

		self.entries = self.allocator.alloc(Entry(K, V), new_len).?
		self.metadata = self.allocator.alloc(u8, new_len).?.ptr
		mem.set(self.metadata[0..self.entries.len], vacant)

		self.size = 0
		self.tombstones = 0

		i := 0
		loop if i >= old_entries.len break else {
			if (old_metadata + i).* < tombstone {
				old_entry := old_entries[i]
				_ = @inline(self.insert, old_entry.key, old_entry.value)
			}
			i += 1
		}

		self.allocator.dealloc(Entry(K, V), old_entries)
		self.allocator.dealloc(u8, old_metadata[0..prev_len])
	}
	insert := fn(self: ^Self, key: K, value: V): ?^V {
		if $target.current == .hbvm_ableos {
			if self.size + self.tombstones >= 99 * self.entries.len >> 7 self._rehash()
		} else {
			if self.size + self.tombstones >= 5 * self.entries.len >> 3 self._rehash()
		}
		hash := self.hash_key(key)
		short_hash: u8 = @int_cast(hash >> 57)
		mask := self.entries.len - 1
		idx := hash & mask
		candidate: ?uint = null
		loop {
			meta := self.metadata + idx
			if meta.* == short_hash {
				entry := self.entries.ptr + idx
				if entry.key == key {
					entry.value = value
					return &entry.value
				}
			} else if meta.* >= tombstone {
				if meta.* == vacant {
					if candidate != null {
						self.tombstones -= 1
						idx = candidate.?
					}
					meta = self.metadata + idx
					entry := self.entries.ptr + idx
					entry.* = .(key, value)
					meta.* = short_hash
					self.size += 1
					return &entry.value
				} else {
					if candidate == null candidate = idx
				}
			}
			idx += 1
			idx &= mask
		}
	}
	get := fn(self: ^Self, key: K): ?^V {
		hash := self.hash_key(key)
		short_hash: u8 = @int_cast(hash >> 57)
		mask := self.entries.len - 1
		idx := hash & mask
		loop {
			meta := self.metadata + idx
			if meta.* == short_hash {
				entry := self.entries.ptr + idx
				if entry.key == key return &entry.value
			} else if meta.* == vacant return null
			idx += 1
			idx &= mask
		}
	}
	remove := fn(self: ^Self, key: K): ?V {
		hash := self.hash_key(key)
		short_hash: u8 = @int_cast(hash >> 57)
		mask := self.entries.len - 1
		idx := hash & mask
		loop {
			meta := self.metadata + idx
			if meta.* == short_hash {
				entry := self.entries.ptr + idx
				if entry.key == key {
					meta.* = tombstone
					self.size -= 1
					self.tombstones += 1
					return entry.value
				}
			} else if meta.* == vacant return null
			idx += 1
			idx &= mask
		}
	}
	$_fmt := fn(self: ^Self, buf: []u8): uint {
		mem.copy(buf, @name_of(Entry(K, V)))
		len := @name_of(Entry(K, V)).len
		mem.copy(buf[len..], ".[")
		len += 2
		meta := self.metadata
		entry := self.entries.ptr
		i := 0
		loop if i >= self.size break else {
			if meta.* < tombstone {
				if i > 0 {
					mem.copy(buf[len..], ", ")
					len += 2
				}
				len += entry._fmt(buf[len..])
				i += 1
			}
			meta += 1
			entry += 1
		}
		buf[len] = ']'
		return len + 1
	}
}
