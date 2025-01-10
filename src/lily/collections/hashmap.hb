.{collections: .{Vec}} := @use("../lib.hb")

Item := fn($Key: type, $Value: type): type return packed struct {
	key: Key,
	value: Value,
}

Bucket := fn($Key: type, $Value: type, $Allocator: type): type return Vec(Item(Key, Value), Allocator)
Buckets := fn($Key: type, $Value: type, $Allocator: type): type return Vec(Bucket(Key, Value, Allocator), Allocator)

HashMap := fn($Key: type, $Value: type, $Hasher: type, $Allocator: type): type return struct {
	allocator: ^Allocator,
	hasher: Hasher,
	buckets: Buckets(Key, Value, Allocator),
	length: uint,

	new := fn(allocator: ^Allocator): Self {
		hasher := Hasher.default()
		buckets := Buckets(Key, Value, Allocator).new(allocator)
		return .(allocator, hasher, buckets, 0)
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
		idx := self.hasher.finish() % self.buckets.len()
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null {
			self.buckets.push(Bucket(Key, Value, Allocator).new(self.allocator))
			bucket = @unwrap(self.buckets.get_ref(self.buckets.len() - 1))
		}

		i := 0
		loop if i == self.buckets.len() break else {
			defer i += 1
			pair := @unwrap(bucket).get_ref(i)
			if pair == null break
			if pair.key == key {
				pair.value = value
			}
			return &@as(^Item(Key, Value), pair).value
		}

		@unwrap(bucket).push(.{key, value})
		pair := @unwrap(@unwrap(bucket).get_ref(@unwrap(bucket).len() - 1))
		self.length += 1
		return &@as(^Item(Key, Value), pair).value
	}
	get := fn(self: ^Self, key: Key): ?Value {
		self.hasher.write(key)
		idx := self.hasher.finish() % self.buckets.len()
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null return null
		i := 0
		loop if i == self.buckets.len() break else {
			defer i += 1
			pair := bucket.get_ref(i)
			if pair == null break
			if pair.key == key {
				return pair.value
			}
		}
		return null
	}
	get_ref := fn(self: ^Self, key: Key): ?^Value {
		self.hasher.write(key)
		idx := self.hasher.finish() % self.buckets.len()
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null return null
		i := 0
		loop if i == self.buckets.len() break else {
			defer i += 1
			pair := bucket.get_ref(i)
			if pair == null break
			if pair.key == key {
				return &@as(^Item(Key, Value), pair).value
			}
		}
		return null
	}
	remove := fn(self: ^Self, key: Key): ?Value {
		self.hasher.write(key)
		idx := self.hasher.finish() % self.buckets.len()
		self.hasher.reset()

		bucket := self.buckets.get_ref(idx)
		if bucket == null return null
		i := 0
		loop if i == self.buckets.len() break else {
			defer i += 1
			pair := bucket.get_ref(i)
			if pair == null break
			if pair.key == key {
				self.length -= 1
				return @unwrap(bucket.remove(i)).value
			}
		}
		return null
	}
	$len := fn(self: ^Self): uint return self.len
}