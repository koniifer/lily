lily.{iter, TypeInfo, log, mem, target, math} := @use("../lib.hb")

Entry := fn($K: type, $V: type): type return struct align(1) {
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
		// yes i know this should be randomly seeded with .default()
		// however there is an incongruence between the results of x86 and hbvm
		// so im leaving this as is.
		return .(metadata, entries, .new(100), allocator, 0, 0)
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

		self.entries = self.allocator.alloc(Entry(K, V), old_entries.len * 2).?
		self.metadata = self.allocator.alloc(u8, old_entries.len * 2).?.ptr
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
		self.allocator.dealloc(u8, old_metadata[0..old_entries.len])
	}
	insert := fn(self: ^Self, key: K, value: V): ?^V {
		if self.size + self.tombstones >= self.entries.len - (self.entries.len >> 3) self._rehash()
		hash := self.hash_key(key)
		step := hash >> 32 | 1
		short_hash: u8 = @int_cast(hash >> 57)
		mask := self.entries.len - 1
		idx := hash & mask
		candidate: ?uint = null
		loop {
			meta := self.metadata + idx
			entry := self.entries.ptr + idx
			if meta.* == vacant {
				break
			} else if meta.* == tombstone {
				if candidate == null candidate = idx
			} else if meta.* == short_hash {
				if entry.key == key {
					entry.value = value
					return &entry.value
				}
			}
			idx += step
			idx &= mask
		}
		if candidate != null {
			self.tombstones -= 1
			idx = candidate.?
		}
		meta := self.metadata + idx
		entry := self.entries.ptr + idx
		entry.* = .(key, value)
		meta.* = short_hash
		self.size += 1
		return &entry.value
	}
	get := fn(self: ^Self, key: K): ?^V {
		hash := self.hash_key(key)
		step := hash >> 32 | 1
		short_hash: u8 = @int_cast(hash >> 57)
		mask := self.entries.len - 1
		idx := hash & mask
		loop {
			meta := self.metadata + idx
			if meta.* == vacant return null
			entry := self.entries.ptr + idx
			if meta.* == short_hash {
				if entry.key == key return &entry.value
			}
			idx += step
			idx &= mask
		}
	}
	remove := fn(self: ^Self, key: K): ?V {
		hash := self.hash_key(key)
		step := hash >> 32 | 1
		short_hash: u8 = @int_cast(hash >> 57)
		mask := self.entries.len - 1
		idx := hash & mask
		loop {
			meta := self.metadata + idx
			if meta.* == vacant return null
			entry := self.entries.ptr + idx
			if meta.* == short_hash {
				if entry.key == key {
					meta.* = tombstone
					self.size -= 1
					self.tombstones += 1
					return entry.value
				}
			}
			idx += step
			idx &= mask
		}
	}
	$_fmt := fn(self: ^Self, buf: []u8): uint {
		mem.copy(buf, @name_of(Entry(K, V)))
		len := @name_of(Entry(K, V)).len
		mem.copy(buf[len..], ".[")
		len += 2
		comma := false
		meta := self.metadata
		entry := self.entries.ptr
		i := 0
		loop if i >= self.size break else {
			if meta.* < tombstone {
				// yes, i can check if i > 0. yes i know.
				// left this here because there is a bug on x86_64-linux
				// causing an extra comma to print at the start
				if comma {
					mem.copy(buf[len..], ", ")
					len += 2
				}
				len += entry._fmt(buf[len..])
				comma = true
				i += 1
			}
			meta += 1
			entry += 1
		}
		buf[len] = ']'
		return len + 1
	}
}
