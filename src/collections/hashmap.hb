lily.{collections: .{Vec}, iter, TypeInfo, log, mem, target, math} := @use("../lib.hb")

Entry := fn($K: type, $V: type): type return struct align(_entry_align(K, V)) {
	.key: K;
	.value: V;
	.status: enum {
		.Occupied;
		.Vacant;
		.Deleted;
	}

	$_fmt := fn(self: ^@CurrentScope(), buf: []u8): uint {
		return lily.fmt.format(buf, .(self.key, self.value))
	}
}

$_entry_align := fn($K: type, $V: type): uint {
	// in hbvm contexts, penalisation from align = 1 is minimal
	// and may save some memory
	$match target.current {
		.AbleOS => return 1,
		_ => $if @align_of(K) > @align_of(V) return @align_of(K) else return @align_of(V),
	}
}

HashMap := fn($K: type, $V: type, $A: type, $H: type): type return struct {
	.entries: Vec(Entry(K, V), A);
	.hasher: H;
	.size: uint;
	.tombstones: uint

	Self := @CurrentScope()

	$new := fn(allocator: ^A): Self {
		entries := Vec(Entry(K, V), A).new_with_capacity(allocator, 32)
		entries.fill_with(&@as(Entry(K, V), .(idk, idk, .Vacant)))
		return .(entries, .default(), 0, 0)
	}
	$new_with_args := fn(allocator: ^A, hasher: ?H, capacity: ?uint): Self {
		if hasher == null hasher = H.default()
		if capacity == null capacity = 16 else capacity = math.int_next_power_of_two(capacity.?)
		entries := Vec(Entry(K, V), A).new_with_capacity(allocator, capacity.?)
		entries.fill_with(&@as(Entry(K, V), .(idk, idk, .Vacant)))
		return .(entries, hasher.?, 0, 0)
	}
	$deinit := fn(self: ^Self): void {
		self.entries.deinit()
		self.hasher.deinit()
		self.* = idk
	}
	$hash_key := fn(self: ^Self, key: K): uint {
		self.hasher.reset()
		self.hasher.write(key)
		return self.hasher.finish()
	}
	_rehash := fn(self: ^Self): void {
		new_entries := Vec(Entry(K, V), A).new_with_capacity(self.entries.allocator, self.entries.cap * 2)
		new_entries.fill_with(&@as(Entry(K, V), .(idk, idk, .Vacant)))

		old_entries := self.entries
		self.entries = new_entries
		self.size = 0
		self.tombstones = 0

		i := 0
		loop if i >= old_entries.cap break else {
			old_entry := old_entries.get_ref_unchecked(i)
			if old_entry.status == .Occupied {
				_ = @inline(self.insert, old_entry.key, old_entry.value)
			}
			i += 1
		}

		old_entries.deinit()
	}
	// todo: compact using number of tombstones
	insert := fn(self: ^Self, key: K, value: V): ?^V {
		if self.size * 2 >= self.entries.cap {
			self._rehash()
		}
		mask := self.entries.cap - 1
		hash := self.hash_key(key)
		start_idx := hash & mask
		step := hash >> 32 | 1
		idx := start_idx
		entry: ^Entry(K, V) = idk
		tombstone: ?^Entry(K, V) = null

		loop {
			entry = self.entries.get_ref_unchecked(idx)
			match entry.status {
				.Occupied => if entry.key == key {
					entry.value = value
					return &entry.value
				},
				.Deleted => if tombstone == null {
					tombstone = entry
					self.tombstones -= 1
				},
				_ => {
					if tombstone != null entry = tombstone.?
					break
				},
			}
			idx = idx + step & mask
			if start_idx == idx return null
		}
		entry.key = key
		entry.value = value
		entry.status = .Occupied
		self.size += 1
		return &entry.value
	}
	get := fn(self: ^Self, key: K): ?^V {
		mask := self.entries.cap - 1
		hash := self.hash_key(key)
		start_idx := hash & mask
		step := hash >> 32 | 1
		idx := start_idx
		loop {
			entry := self.entries.get_ref_unchecked(idx)
			match entry.status {
				.Occupied => if entry.key == key return &entry.value,
				.Vacant => return null,
				_ => {
				},
			}
			idx = idx + step & mask
			if start_idx == idx return null
		}
	}
	remove := fn(self: ^Self, key: K): ?V {
		mask := self.entries.cap - 1
		hash := self.hash_key(key)
		start_idx := hash & mask
		step := hash >> 32 | 1
		idx := start_idx
		loop {
			entry := self.entries.get_ref_unchecked(idx)
			match entry.status {
				.Occupied => if entry.key == key {
					entry.status = .Deleted
					self.size -= 1
					self.tombstones += 1
					return entry.value
				},
				.Vacant => return null,
				_ => {
				},
			}
			idx = idx + step & mask
			if start_idx == idx return null
		}
	}
	$_fmt := fn(self: ^Self, buf: []u8): uint {
		i := 0
		mem.copy(buf, @name_of(Entry(K, V)))
		len := @name_of(Entry(K, V)).len
		mem.copy(buf[len..], ".[")
		len += 2
		comma := false
		loop if i == self.entries.cap break else {
			entry := self.entries.get_ref_unchecked(i)
			if entry.status == .Occupied {
				if comma {
					mem.copy(buf[len..], ", ")
					len += 2
				}
				len += entry._fmt(buf[len..])
				comma = true
			}
			i += 1
		}
		buf[len] = ']'
		return len + 1
	}
}
