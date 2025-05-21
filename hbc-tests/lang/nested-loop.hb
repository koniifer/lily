expectations := .{
	return_value: 20365011074,
}

main := fn(): uint {
	n_sup := 0
	m := 0
	loop if n_sup == 1 break else {
		a := 0
		b := 1
		n := 0
		loop if n == 50 break else {
			m = a + b
			a = b
			b = m
			n += 1
		}
		n_sup += 1
	}
	return m
}
