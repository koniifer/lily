.{TypeOf} := @use("lib.hb")

IterNext := fn($T: type): type return struct {finished: bool, val: T}

/// Iterator struct. Implements iterator stuff for you if you implement `into_iter` for your struct.
Iterator := fn($T: type): type {
	$A := @TypeOf(T.next(idk))

	return struct {
		inner: T,
		$next := fn(self: ^Self): A {
			return self.inner.next()
		}
		$map := fn(self: Self, $_map: type): Iterator(Map(T, _map)) {
			return .(.(self))
		}
		$enumerate := fn(self: Self): Iterator(Enumerate(T)) {
			return .(.(self, 0))
		}
		for_each := fn(self: ^Self, $_for_each: type): void {
			loop {
				x := self.next()
				if x.finished break
				_ = _for_each(x.val)
			}
		}
	}
}

/// Map is lazy. Simply calling `my_iter.map(func)` will not cause any execution.
Map := fn($T: type, $_map: type): type {
	$M := @TypeOf(_map(@as(@TypeOf(T.next(idk).val), idk)))

	return struct {
		iter: Iterator(T),
		next := fn(self: ^Self): IterNext(M) {
			x := self.iter.inner.next()
			return .(x.finished, _map(x.val))
		}
	}
}

IterEnumerate := fn($T: type): type return struct {n: uint, val: T}

Enumerate := fn($T: type): type {
	$A := IterEnumerate(@TypeOf(T.next(idk).val))
	return struct {
		iter: Iterator(T),
		n: uint,
		next := fn(self: ^Self): IterNext(A) {
			self.n += 1
			x := self.iter.inner.next()
			return .(x.finished, .(self.n, x.val))
		}
	}
}

SliceIter := fn($T: type): type return struct {
	slice: []T,
	cursor: uint,

	next := fn(self: ^Self): IterNext(?T) {
		if self.cursor >= self.slice.len return .(true, null)
		tmp := self.slice[self.cursor]
		self.cursor += 1
		return .(false, tmp)
	}
}