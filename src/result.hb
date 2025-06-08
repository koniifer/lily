lily.{config} := @use("lib.hb")

Result := fn($Ok: type, $Error: type): type return struct {
	.inner: union{.ok: Ok; .err: Error};
	.is_ok: bool

	Self := @CurrentScope()

	$ok := fn(v: Ok): Self {
		return .(.{ok: v}, true)
	}
	$err := fn(e: Error): Self {
		return .(.{err: e}, false)
	}
	$unwrap := fn(self: Self): Ok return self.expect("result: unwrap on error variant.")
	$unwrap_err := fn(self: Self): Ok return self.expect_err("result: unwrap_err on ok variant.")
	$expect := fn(self: Self, msg: []u8): Ok {
		$if config.optimise < .ReleaseFast {
			if self.is_ok return self.inner.ok
			lily.panic(msg)
		}
		return self.inner.ok
	}
	$expect_err := fn(self: Self, msg: []u8): Error {
		$if config.optimise < .ReleaseFast {
			if self.is_ok lily.panic(msg)
		}
		return self.inner.err
	}
	$map := fn(self: Self, $fnc: type): Result(@TypeOf(fnc(idk)), Error) {
		if self.is_ok return .ok(fnc(self.inner.ok))
		return .err(self.inner.err)
	}
	$map_err := fn(self: Self, $fnc: type): Result(Ok, @TypeOf(fnc(idk))) {
		if self.is_ok return .err(fnc(self.inner.err))
		return .ok(self.inner.ok)
	}
	$to_ok := fn(self: Self): ?Ok {
		if self.is_ok return self.inner.ok
		return null
	}
	$to_err := fn(self: Self): ?Error {
		if self.is_ok return null
		return self.inner.err
	}
}
