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
$occupied: u8 = 0x7F

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
		mem.fill(mem.as_bytes(metadata[0..entries.len]), mem.as_bytes(&vacant))
		return .(metadata, entries, .default(), allocator, 0, 0)
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
		mem.fill(mem.as_bytes(self.metadata[0..self.entries.len]), mem.as_bytes(&vacant))

		self.size = 0
		self.tombstones = 0

		i := 0
		loop if i >= old_entries.len break else {
			old_meta := (old_metadata + i).*
			if (old_meta & occupied) == old_meta {
				old_entry := old_entries[i]
				_ = @inline(self.insert, old_entry.key, old_entry.value)
			}
			i += 1
		}
	}
	insert := fn(self: ^Self, key: K, value: V): ?^V {
		if (self.size + self.tombstones) * 2 >= self.entries.len self._rehash()
		hash := self.hash_key(key)
		step := hash >> 32 | 1
		short_hash: u8 = @int_cast(hash >> 57) & occupied
		mask := self.entries.len - 1
		idx := hash & mask
		loop {
			meta := self.metadata + idx
			entry := self.entries.ptr + idx
			if meta.* == vacant | meta.* == tombstone {
				self.tombstones -= meta.* == tombstone
				entry.* = .(key, value)
				meta.* = short_hash
				self.size += 1
				return &entry.value
			}
			if meta.* == short_hash {
				if entry.key == key {
					entry.value = value
					return &entry.value
				}
			}
			idx = idx + step & mask
		}
	}
	get := fn(self: ^Self, key: K): ?^V {
		hash := self.hash_key(key)
		step := hash >> 32 | 1
		short_hash: u8 = @int_cast(hash >> 57) & occupied
		mask := self.entries.len - 1
		idx := hash & mask
		loop {
			meta := self.metadata + idx
			if meta.* == vacant return null
			entry := self.entries.ptr + idx
			if meta.* == short_hash {
				if entry.key == key return &entry.value
			}
			idx = idx + step & mask
		}
	}
	remove := fn(self: ^Self, key: K): ?V {
		hash := self.hash_key(key)
		step := hash >> 32 | 1
		short_hash: u8 = @int_cast(hash >> 57) & occupied
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
			idx = idx + step & mask
		}
	}
	$_fmt := fn(self: ^Self, buf: []u8): uint {
		i := 0
		mem.copy(buf, @name_of(Entry(K, V)))
		len := @name_of(Entry(K, V)).len
		mem.copy(buf[len..], ".[")
		len += 2
		comma := false
		loop if i == self.entries.len break else {
			meta := (self.metadata + i).*
			if (meta & occupied) == meta {
				if comma {
					mem.copy(buf[len..], ", ")
					len += 2
				}
				len += (self.entries.ptr + i)._fmt(buf[len..])
				comma = true
			}
			i += 1
		}
		buf[len] = ']'
		return len + 1
	}
}
