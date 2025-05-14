lily.{target, mem, Type} := @use("lib.hb")

Buffer := struct {
	.id: uint

	Self := @CurrentScope()

	new := fn(name: ?[]u8): ?Self {
		id: uint = 0
		if name == null {
			id = target.buf_create()
		} else {
			id = target.buf_create_named(name.?)
		}
		if id == 0 return null
		return Self.from_raw(id)
	}
	search := fn(name: []u8): ?Self {
		id := target.buf_search(name)
		if id == 0 return null
		return Self.from_raw(id)
	}
	connect := fn(name: []u8): Self {
		loop {
			id := target.buf_search(name)
			if id != 0 return Self.from_raw(id)
		}
	}
	deinit := fn(self: ^Self): void {
		target.buf_destroy(self.id)
		self.* = idk
	}
	$from_raw := fn(id: uint): Self {
		return .(id)
	}
	$await := fn(self: ^Self): void {
		target.buf_await(self.id)
	}
	$write := fn(self: ^Self, val: @Any()): void {
		$match Type(@TypeOf(val)).kind() {
			.Pointer => target.buf_write(self.id, mem.as_bytes(val)),
			.Slice => target.buf_write(self.id, mem.as_bytes(val)),
			_ => target.buf_write(self.id, mem.as_bytes(&val)),
		}
	}
	$read_into := fn(self: ^Self, slice: []u8): void {
		target.buf_read(self.id, slice)
	}
	$read := fn(self: ^Self, $T: type): T {
		buf: T = idk
		target.buf_read(self.id, mem.as_bytes(&buf))
		return buf
	}
}

Channel := struct {
	.local: Buffer;
	.remote: Buffer

	Self := @CurrentScope()

	new := fn(local_name: ?[]u8, remote_name: ?[]u8): ?Self {
		local := Buffer.new(local_name)
		if local == null return null
		remote := Buffer.new(remote_name)
		if remote == null return null
		return .(local.?, remote.?)
	}
	search := fn(local_name: []u8, remote_name: []u8): ?Self {
		local := Buffer.search(local_name)
		if local == null return null
		remote := Buffer.search(remote_name)
		if remote == null return null
		return .(local.?, remote.?)
	}
	connect := fn(local_name: []u8, remote_name: []u8): Self {
		local: ?Buffer = null
		remote: ?Buffer = null
		loop {
			if local == null local = Buffer.search(local_name)
			if remote == null remote = Buffer.search(remote_name)
			if local != null & remote != null return .(local.?, remote.?)
		}
	}
	$deinit := fn(self: ^Self): void {
		self.local.deinit()
		self.remote.deinit()
		self.* = idk
	}
	$to_remote := fn(self: Self): Self {
		return .(self.remote, self.local)
	}
	$from_raw := fn(local_id: uint, remote_id: uint): Self {
		return .(Buffer.from_raw(local_id), Buffer.from_raw(remote_id))
	}
	$await := fn(self: ^Self): void {
		self.local.await()
	}
	$write := fn(self: ^Self, val: @Any()): void {
		self.remote.write(val)
	}
	$read_into := fn(self: ^Self, slice: []u8): void {
		self.local.read_into(slice)
	}
	$read := fn(self: ^Self, $T: type): T {
		return self.local.read(T)
	}
}
