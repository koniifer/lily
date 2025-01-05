.{target, TypeOf, Type} := @use("lib.hb")

// ! NON CRYPTOGRAPHIC, TEMPORARY
SimpleRandom := struct {
	seed: uint,
	$new := fn(): Self return Self.(0)
	$deinit := fn(self: ^Self): void {
		self.seed = 0
	}
	$any := fn(self: ^Self, $A: type): A {
		T := Type(A)
		match T.kind() {
			.Slice => @error("Use SimpleRandom.fill or SimpleRandom.fill_values instead."),
			.Array => @error("Use SimpleRandom.fill or SimpleRandom.fill_values instead."),
			_ => {
			},
		}
		if T.is_bool() {
			a: A = idk
			target.getrandom(@bitcast(&a), 1)
			return @bitcast(a & @as(u8, 1))
		}
		a: A = idk
		target.getrandom(@bitcast(&a), T.size())
		return a
	}
	/// Accepts any type for min and max (as long as it is the same for both).
	$range := fn(self: ^Self, min: @Any(), max: @TypeOf(min)): @TypeOf(min) {
		return self.any(@TypeOf(min)) % (max - min) + min
	}
	/// Fills an array or slice with random bytes
	$fill := fn(self: ^Self, buf: @Any()): void {
		T := TypeOf(buf)
		match T.kind() {
			.Slice => target.getrandom(@bitcast(buf.ptr), buf.len * T.Child().size()),
			.Array => target.getrandom(@bitcast(&buf), T.size()),
			_ => @error("Can only fill bytes of Slice or Array."),
		}
	}
	/// Fills an array or slice with random values
	// ! (compiler) bug: `buf[i]` causing compiler panic here
	fill_values := fn(self: ^Self, buf: @Any()): void {
		T := TypeOf(buf)
		match T.kind() {
			.Slice => {
				len := buf.len * T.Child().size()
				i := 0
				loop if i == len break else {
					buf[i] = self.any(T.Child().This())
					i += 1
				}
			},
			.Array => {
				len := T.size()
				i := 0
				$loop if i == len break else {
					buf[i] = self.any(T.Child().This())
					i += 1
				}
			},
			_ => @error("Can only fill values of Slice or Array."),
		}
	}
}