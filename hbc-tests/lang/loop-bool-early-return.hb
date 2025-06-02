expectations := .{
	return_value: 1,
}

d: u8 = 0xFF
b := u8.[0, 0]

main := fn(): uint {
	a := false
	// x86: if you replace b with 'u8.[0, 0]' then you get a program segfault
	c: ^u8 = @bit_cast(&b)
	i := 0
	x := 0
	loop if i == @len_of(@TypeOf(b)) break else {
		// if you replace d with '0x80' then you get another bug
		if c.* < d {
			if a return i
			a = true
			i += 1
		}
		c += 1
	}
	return 255
}