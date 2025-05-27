expectations := .{
	return_value: 0,
}

float32 := fn(): f32 return -1.0

float64 := fn(): f64 return -1.0

cond_negate := fn(v: @Any()): @TypeOf(v) {
	if v < 0.0 {
		v = -v
	}
	// second branch here to catch a bug
	if v == 0.0 {
		return 0.0
	}
	return v
}

main := fn(): uint {
	if float32() > 0.0 return 1
	if float64() > 0.0 return 2
	if cond_negate(float32()) < 0.0 return 3
	if cond_negate(float64()) < 0.0 return 4
	return 0
}
