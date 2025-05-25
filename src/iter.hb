lily.{Type, alloc: .{Vec}} := @use("lib.hb")

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

	Self := @CurrentScope()

	$next := fn(self: ^Self): IterNext {
		return self.inner.next()
	}
	$map := fn(self: ^Self, $func: type): Iterator(Map(T, func)) {
		return .(.(self))
	}
	$enumerate := fn(self: ^Self): Iterator(Enumerate(T)) {
		return .(.(self, 0))
	}
	$take := fn(self: ^Self, end: uint): Iterator(Take(T)) {
		return .(.(self, 0, end))
	}
	$skip := fn(self: ^Self, n: uint): Iterator(Skip(T)) {
		return .(.(self, n))
	}
	$chain := fn(self: ^Self, rhs: @Any()): Iterator(Chain(T, @TypeOf(rhs))) {
		return .(.(self, rhs, .Iter0))
	}
	$for_each := fn(self: ^Self, $func: type): void {
		loop {
			x := self.next()
			if x.finished break
			_ = func(x.val)
		}
	}
	$fold := fn(self: ^Self, $func: type, sum: @Any()): @TypeOf(sum) {
		loop {
			x := self.next()
			if x.finished return sum
			sum = func(sum, x.val)
		}
	}
	nth := fn(self: ^Self, n: uint): ?IterVal {
		i := 0
		loop {
			defer i += 1
			x := self.next()
			if x.finished return null else {
				if i == n return x.val
			}
		}
	}
	collect := fn(self: ^Self, $A: type): ?A {
		$if Type(A).kind() != .Array {
			@error("collecting", Self, "into type", A, "unsupported for now")
		}
		$if @ChildOf(A) != IterVal {
			@error("cannot collect of iterator of type", IterVal, "into type", A)
		}
		cont: A = idk
		i := 0
		loop {
			defer i += 1
			x := self.next()
			if i == @len_of(A) & x.finished return cont
			if i == @len_of(A) | x.finished return null
			cont[i] = x.val
		}
	}
	collect_vec := fn(self: ^Self, allocator: @Any()): Vec(IterVal, @ChildOf(@TypeOf(allocator))) {
		vec := Vec(IterVal, @ChildOf(@TypeOf(allocator))).new(allocator)
		loop {
			x := self.next()
			if x.finished return vec
			vec.push(x.val)
		}
	}
}

Map := fn(T: type, func: type): type return struct {
	.iter: ^Iterator(T)
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

Skip := fn($T: type): type return struct {
	.iter: ^Iterator(T);
	.step: uint
	IterNext := @TypeOf(T.next(idk).val)

	$next := fn(self: ^@CurrentScope()): Next(IterNext) {
		n := 0
		loop {
			x := self.iter.next()
			if n == self.step | x.finished return x
			n += 1
		}
	}
}

Chain := fn($A: type, $B: type): type {
	Iter0Next := @TypeOf(A.next(idk).val)
	Iter1Next := @TypeOf(B.next(idk).val)

	$if Iter0Next != Iter1Next @error(Iter0Next, " != ", Iter1Next)

	return struct {
		.iter0: ^Iterator(A)
		/* todo: ^B? */;
		.iter1: B;
		.state: enum{.Iter0; .Iter0Finished; .BothFinished}

		next := fn(self: ^@CurrentScope()): Next(Iter0Next) {
			// todo: replace with Type(T).uninit()
			x: Next(Iter0Next) = idk
			match self.state {
				.Iter0 => {
					x = self.iter0.inner.next()
					if x.finished {
						self.state = .Iter0Finished
						return self.next()
					}
				},
				.Iter0Finished => {
					x = self.iter1.inner.next()
					if x.finished self.state = .BothFinished
				},
				_ => {
				},
			}
			return .(self.state == .BothFinished, x.val)
		}
	}
}
