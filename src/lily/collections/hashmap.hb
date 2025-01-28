.{collections: .{Vec}, iter: .{Iterator, IterNext}, Type, TypeOf, log} := @use("../lib.hb")

Item := fn($Key: type, $Value: type): type return packed struct {
	key: Key,
	value: Value,
}

Bucket := fn($Key: type, $Value: type, $Allocator: type): type {
	return Vec(Item(Key, Value), Allocator)
}
Buckets := fn($Key: type, $Value: type, $Allocator: type): type {
	return Vec(Bucket(Key, Value, Allocator), Allocator)
}

$equals := fn(lhs: @Any(), rhs: @TypeOf(lhs)): bool {
	match TypeOf(lhs).kind() {
		.Slice => return lhs.ptr == rhs.ptr & lhs.len == rhs.len,
		_ => return lhs == rhs,
	}
}

// temporarily here.
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

HashMap := fn($Key: type, $Value: type, $Hasher: type, $Allocator: type): type return struct {
	allocator: ^Allocator,
	hasher: Hasher,
	buckets: Buckets(Key, Value, Allocator),
	length: uint,

	new := fn(allocator: ^Allocator): Self {
		hasher := Hasher.default()
		buckets := Buckets(Key, Value, Allocator).with_capacity(allocator, 16)
		// ! (compiler) bug: have to use for-loop here rather than using buckets.len(), otherwise we loop infinitely
		i := 0
		loop if i == 16 break else {
			defer i += 1
			buckets.push(Bucket(Key, Value, Allocator).new(allocator))
		}
		// also need to add this here...?
		buckets.slice.len = 16
		return .(allocator, hasher, buckets, 0)
	}
	// seems like bad performance...
	resize := fn(self: ^Self): void {
		new_cap := next_power_of_two(self.buckets.len() * 2)
		new_buckets := @TypeOf(self.buckets).with_capacity(self.allocator, new_cap)
		// same compiler bug as above...
		i := 0
		loop if i == new_cap break else {
			defer i += 1
			new_buckets.push(Bucket(Key, Value, Allocator).new(self.allocator))
		}
		new_buckets.slice.len = new_cap
		loop if self.buckets.len() == 0 break else {
			bucket := self.buckets.pop_unchecked()
			loop if bucket.len() == 0 break else {
				item := bucket.pop_unchecked()
				self.hasher.write(item.key)
				idx := self.hasher.finish() & new_cap - 1
				self.hasher.reset()
				new_bucket := new_buckets.get_ref_unchecked(idx)
				new_bucket.push(item)
			}
			bucket.deinit()
		}
		self.buckets.deinit()
		self.buckets = new_buckets
	}
	deinit := fn(self: ^Self): void {
		loop {
			bucket := self.buckets.pop()
			if bucket == null break;
			bucket.deinit()
		}
		self.buckets.deinit()
		self.hasher.deinit()
		self.length = 0
	}
	insert := fn(self: ^Self, key: Key, value: Value): ^Value {
		self.hasher.write(key)
		idx := self.hasher.finish() & self.buckets.len() - 1
		self.hasher.reset()

		if self.length * 4 > self.buckets.len() * 3 {
			@inline(self.resize)
		}

		bucket_opt := self.buckets.get_ref(idx)
		if bucket_opt == null {
			self.buckets.push(Bucket(Key, Value, Allocator).new(self.allocator))
			bucket_opt = self.buckets.get_ref(self.buckets.len() - 1)
		}

		bucket := @unwrap(bucket_opt)

		i := 0
		loop if i == bucket.len() break else {
			defer i += 1
			pair := bucket.get_ref_unchecked(i)
			if equals(pair.key, key) {
				pair.value = value
				// ! weird no-op cast to stop type system from complaining.
				// don't quite know what is going on here...
				return &@as(^Item(Key, Value), pair).value
			}
		}
		bucket.push(.{key, value})
		pair := bucket.get_ref_unchecked(bucket.len() - 1)
		self.length += 1
		return &@as(^Item(Key, Value), pair).value
	}
	get := fn(self: ^Self, key: Key): ?Value {
		self.hasher.write(key)
		idx := self.hasher.finish() & self.buckets.len() - 1
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null return null
		i := 0
		loop if i == bucket.len() break else {
			defer i += 1
			pair := bucket.get_ref_unchecked(i)
			if equals(pair.key, key) {
				return pair.value
			}
		}
		return null
	}
	// references may be invalidated if value is removed from hashmap after get_ref is used.
	get_ref := fn(self: ^Self, key: Key): ?^Value {
		self.hasher.write(key)
		idx := self.hasher.finish() & self.buckets.len() - 1
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null return null
		i := 0
		loop if i == bucket.len() break else {
			defer i += 1
			pair := bucket.get_ref_unchecked(i)
			if equals(pair.key, key) {
				return &@as(^Item(Key, Value), pair).value
			}
		}
		return null
	}
	remove := fn(self: ^Self, key: Key): ?Value {
		self.hasher.write(key)
		idx := self.hasher.finish() & self.buckets.len() - 1
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null return null
		i := 0
		loop if i == bucket.len() break else {
			defer i += 1
			pair := bucket.get_ref_unchecked(i)
			if equals(pair.key, key) {
				self.length -= 1
				return @unwrap(bucket.swap_remove(i)).value
			}
		}
		return null
	}
	// todo: write keys, values
	$items := fn(self: Self): Iterator(Items(Self, Item(Key, Value))) {
		return .(.(self, 0, 0))
	}
	$keys := fn(self: Self): Iterator(Keys(Self, Key)) {
		return .(.(self, 0, 0))
	}
	$values := fn(self: Self): Iterator(Values(Self, Value)) {
		return .(.(self, 0, 0))
	}
	$len := fn(self: ^Self): uint return self.length
}

// todo: make these efficient and reduce code duplication

Items := fn($H: type, $I: type): type return struct {
	// has to be owned here... (possibly due to bug) great...
	map: H,
	bucket: uint,
	sub: uint,
	next := fn(self: ^Self): IterNext(I) {
		bucket := self.map.buckets.get_ref(self.bucket)
		if bucket == null return .(true, Type(I).uninit())
		sub := bucket.get(self.sub)
		if sub == null {
			self.sub = 0
			self.bucket += 1
			return self.next()
		}
		self.sub += 1
		return .(false, sub)
	}
}

Values := fn($H: type, $V: type): type return struct {
	// has to be owned here... (possibly due to bug) great...
	map: H,
	bucket: uint,
	sub: uint,
	next := fn(self: ^Self): IterNext(V) {
		bucket := self.map.buckets.get_ref(self.bucket)
		if bucket == null return .(true, Type(V).uninit())
		sub := bucket.get(self.sub)
		if sub == null {
			self.sub = 0
			self.bucket += 1
			return self.next()
		}
		self.sub += 1
		return .(false, sub.value)
	}
}

Keys := fn($H: type, $K: type): type return struct {
	// has to be owned here... (possibly due to bug) great...
	map: H,
	bucket: uint,
	sub: uint,
	next := fn(self: ^Self): IterNext(K) {
		bucket := self.map.buckets.get_ref(self.bucket)
		if bucket == null return .(true, Type(K).uninit())
		sub := bucket.get(self.sub)
		if sub == null {
			self.sub = 0
			self.bucket += 1
			return self.next()
		}
		self.sub += 1
		return .(false, sub.key)
	}
}