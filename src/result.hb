lily.{config} := @use("lib.hb")

Result := fn($Ok: type, $Error: type): type return struct {
	.inner: union{.ok: Ok; .err: Error};
	.is_ok: bool

	Self := @CurrentScope()

	$ok := fn(v: Ok): Self {
		return .(@bit_cast(v), true)
	}
	$err := fn(e: Error): Self {
		return .(@bit_cast(e), false)
	}
	$unwrap := fn(self: Self): Ok return self.expect("result: unwrap on error variant.")
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
		return self
	}
}
