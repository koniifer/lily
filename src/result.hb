lily.{config} := @use("lib.hb")

Result := fn($T: type, $E: type): type return struct {
	.inner: union{.ok: T; .err: E};
	.is_ok: bool

	Self := @CurrentScope()

	$ok := fn(v: T): Self {
		return .(@bit_cast(v), true)
	}
	$err := fn(e: E): Self {
		return .(@bit_cast(e), false)
	}
	$unwrap := fn(self: Self): T return self.expect("result: unwrap on error variant.")

	$expect := fn(self: Self, msg: []u8): T {
		$if config.optimise < .ReleaseFast {
			if self.is_ok return self.inner.ok
			lily.panic(msg)
		}
		return self.inner.ok
	}
}
