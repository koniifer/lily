Next := fn(T: type): type return struct {
	.finished: bool;
	.val: T

	$yield := fn(val: T): @CurrentScope() return .(false, val)
	$done := fn(): @CurrentScope() return .(true, idk)
}

Iterator := fn(T: type): type return struct {
	.inner: T
	IterNext := @TypeOf(T.next(idk))
	IterVal := @TypeOf(T.next(idk).val)

	$next := fn(self: ^@CurrentScope()): IterNext {
		return self.inner.next()
	}
	$map := fn(self: ^@CurrentScope(), $func: type): Iterator(Map(T, func)) {
		return .(.(self))
	}
	$enumerate := fn(self: ^@CurrentScope()): Iterator(Enumerate(T)) {
		return .(.(self, 0))
	}
	$take := fn(self: ^@CurrentScope(), end: uint): Iterator(Take(T)) {
		return .(.(self, 0, end))
	}
	for_each := fn(self: ^@CurrentScope(), $func: type): void {
		loop {
			x := self.next()
			if x.finished break
			_ = func(x.val)
		}
	}
}

Map := fn(T: type, func: type): type return struct {
	.iter: Iterator(T)
	IterNext := @TypeOf(func(idk))

	$next := fn(self: ^@CurrentScope()): Next(IterNext) {
		x := self.iter.inner.next()
		return .(x.finished, func(x.val))
	}
}

Enumerate := fn($T: type): type return struct {
	.iter: ^Iterator(T);
	.n: uint
	IterNext := struct{.n: uint; .val: @TypeOf(T.next(idk).val)}

	$next := fn(self: ^@CurrentScope()): Next(IterNext) {
		self.n += 1
		x := self.iter.inner.next()
		return .(x.finished, .(self.n, x.val))
	}
}

Take := fn($T: type): type return struct {
	.iter: ^Iterator(T);
	.n: uint;
	.end: uint
	IterNext := @TypeOf(T.next(idk).val)

	$next := fn(self: ^@CurrentScope()): Next(IterNext) {
		self.n += 1
		x: Next(IterNext) = idk
		if self.n > self.end return .(true, x.val)
		return self.iter.inner.next()
	}
}
