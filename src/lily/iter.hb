.{Type} := @use("lib.hb")

IterNext := fn($T: type): type return struct {finished: bool, val: T}

// ! todo: complain about inlining rules
// ! how am i supposed to get optimal performance out of this if inlining is sometimes not allowed

// ! todo:
// * Iterator.peek

/// Iterator struct. Implements iterator stuff for you if you implement `into_iter` for your struct.
Iterator := fn($T: type): type {
	$Next := @TypeOf(T.next(idk))
	$Value := @TypeOf(T.next(idk).val)

	return struct {
		inner: T,
		$next := fn(self: ^Self): Next {
			return self.inner.next()
		}
		$map := fn(self: Self, $_map: type): Iterator(Map(T, _map)) {
			return .(.(self))
		}
		$enumerate := fn(self: Self): Iterator(Enumerate(T)) {
			return .(.{iter: self})
		}
		$take := fn(self: Self, n: uint): Iterator(Take(T)) {
			return .(.{iter: self, end: n})
		}
		$skip := fn(self: Self, n: uint): Iterator(Skip(T)) {
			return .(.{iter: self, step: n})
		}
		$chain := fn(self: Self, rhs: @Any()): Iterator(Chain(T, @TypeOf(rhs))) {
			return .(.{iter0: self, iter1: .(rhs)})
		}
		$intersperse := fn(self: Self, rhs: @Any()): Iterator(Intersperse(T, @TypeOf(rhs))) {
			return .(.{iter0: self, iter1: .(rhs)})
		}
		for_each := fn(self: ^Self, $_for_each: type): void {
			loop {
				x := self.next()
				if x.finished break
				_ = _for_each(x.val)
			}
		}
		fold := fn(self: ^Self, $_fold: type, sum: @Any()): @TypeOf(sum) {
			loop {
				x := self.next()
				if x.finished return sum
				sum = _fold(sum, x.val)
			}
		}
		nth := fn(self: ^Self, n: uint): ?Value {
			i := 0
			loop {
				x := self.next()
				if x.finished return null else if i == n return x.val
				i += 1
			}
		}
		collect := fn(self: ^Self, $A: type): ?A {
			if Type(A).kind() != .Array {
				@error("unsupported collect (for now)")
			}
			if @ChildOf(A) != Value {
				@error("cannot collect of iterator of type", Value, "into type", A)
			}
			cont := Type(A).uninit()
			i := 0
			loop {
				defer i += 1
				x := self.next()
				if i == @lenof(A) & x.finished return cont
				if i == @lenof(A) | x.finished return null
				cont[i] = x.val
			}
		}
	}
}

/// Map is lazy. Simply calling `my_iter.map(func)` will not cause any execution.
Map := fn($T: type, $_map: type): type {
	$Next := @TypeOf(_map(@as(@TypeOf(T.next(idk).val), idk)))

	return struct {
		iter: Iterator(T),
		next := fn(self: ^Self): IterNext(Next) {
			x := self.iter.inner.next()
			return .(x.finished, _map(x.val))
		}
	}
}

IterEnumerate := fn($T: type): type return struct {n: uint, val: T}

Enumerate := fn($T: type): type {
	$Next := IterEnumerate(@TypeOf(T.next(idk).val))
	return struct {
		iter: Iterator(T),
		n: uint = 0,
		next := fn(self: ^Self): IterNext(Next) {
			self.n += 1
			x := self.iter.inner.next()
			return .(x.finished, .(self.n, x.val))
		}
	}
}

Take := fn($T: type): type {
	$Next := @TypeOf(T.next(idk).val)
	return struct {
		iter: Iterator(T),
		n: uint = 0,
		end: uint,
		next := fn(self: ^Self): IterNext(Next) {
			self.n += 1
			x := Type(IterNext(Next)).uninit()
			if self.n > self.end return .(true, x.val)
			return self.iter.inner.next()
		}
	}
}

Skip := fn($T: type): type {
	$Next := @TypeOf(T.next(idk).val)
	return struct {
		iter: Iterator(T),
		step: uint,
		next := fn(self: ^Self): IterNext(Next) {
			n := 0
			loop {
				x := self.iter.next()
				if n == self.step | x.finished return x
				n += 1
			}
		}
	}
}

ChainState := enum {
	Iter0,
	Iter0Finished,
	BothFinished,
}

Chain := fn($A: type, $B: type): type {
	$Next := @TypeOf(A.next(idk).val)
	$Next1 := @TypeOf(B.next(idk).val)
	if Next1 != Next @error("Both iterators should return the same type")

	return struct {
		iter0: Iterator(A),
		iter1: Iterator(B),
		state: ChainState = .Iter0,
		next := fn(self: ^Self): IterNext(Next) {
			x := Type(IterNext(Next)).uninit()
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

IntersperseState := enum {
	Iter0,
	Iter1,
	Iter0Finished,
	Iter1Finished,
}

Intersperse := fn($A: type, $B: type): type {
	$Next := @TypeOf(A.next(idk).val)
	$Next1 := @TypeOf(B.next(idk).val)
	if Next1 != Next @error("Both iterators should return the same type")

	return struct {
		iter0: Iterator(A),
		iter1: Iterator(B),
		state: IntersperseState = .Iter0,
		next := fn(self: ^Self): IterNext(Next) {
			x := Type(IterNext(Next)).uninit()
			match self.state {
				.Iter0 => {
					x = self.iter0.inner.next()
					if x.finished self.state = .Iter0Finished else self.state = .Iter1
				},
				.Iter1 => {
					x = self.iter1.inner.next()
					if x.finished {
						self.state = .Iter1Finished
						return self.next()
					} else self.state = .Iter0
				},
				.Iter1Finished => {
					x = self.iter0.inner.next()
					if x.finished self.state = .Iter0Finished
				},
				_ => {
				},
			}
			return .(self.state == .Iter0Finished, x.val)
		}
	}
}