/*
 * exit: 10
 * timeout: 1s
*/

// ! (compiler) bug: Vec.new and Vec.pop have to be inline functions, otherwise main loops forever.
Vec := struct {
	len: uint,
	new := fn(): Self {
		return .(10)
	}
	pop := fn(self: ^Self): u8 {
		self.len -= 1
		return 0
	}
}

main := fn(): u8 {
	vec := Vec.new()
	i: u8 = 0
	loop if vec.len == 0 break else {
		defer i += 1
		_ = vec.pop()
	}
	return i
}