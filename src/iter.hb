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
	$map := fn(self: ^@CurrentScope(), func: type): Iterator(Map(T, func)) {
		return .(.(self))
	}
}

Map := fn(T: type, func: type): type return struct {
	.iter: Iterator(T)
	IterNext := @TypeOf(func(@as(@TypeOf(T.next(idk).val), idk)))

	next := fn(self: ^@CurrentScope()): Next(IterNext) {
		x := self.iter.inner.next()
		return .(x.finished, func(x.val))
	}
}
