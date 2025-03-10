expected := .{
	exit: 10,
	timeout: 1.0,
}

Vec := struct {
	.len: uint
	new := fn(): Vec {
		return .(10)
	}
	pop := fn(self: ^Vec): u8 {
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
