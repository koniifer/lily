.{exit} := @use("lib.hb")

ResultInner := fn($T: type, $E: type): type return union {ok: T, err: E}

Result := fn($T: type, $E: type): type return struct {
	inner: ResultInner(T, E),
	is_ok: bool,

	$ok := fn(k: T): Self return .(.{ok: k}, true)
	$err := fn(k: E): Self return .(.{err: k}, false)
	$unwrap := fn(self: Self): T return self.expect("Panic: Unwrap on Error Variant.\n\0")
	$unwrap_unchecked := fn(self: Self): T return self.inner.ok
	unwrap_or := fn(self: Self, v: T): T if self.is_ok return self.inner.ok else return v
	unwrap_or_else := fn(self: Self, $F: type): T if self.is_ok return self.inner.ok else return F(self.inner.err)
	expect := fn(self: Self, msg: []u8): T if self.is_ok return self.inner.ok else exit(1)
}