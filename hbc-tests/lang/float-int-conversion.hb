expectations := .{
	return_value: 0,
}

// -1
float32 := fn(): f32 return @bit_cast(@as(u32, 0xBF800000))

// -1
float64 := fn(): f64 return @bit_cast(@as(u64, 0xBFF0000000000000))

opaque := fn(v: @Any()): @TypeOf(v) return v

main := fn(): uint {
	f1 := float32()
	f2 := float64()

	i1 := @float_to_int(f1)
	i2 := @float_to_int(f2)

	f1 *= @int_to_float(i1)
	f1 *= @int_to_float(i2)

	f2 *= @int_to_float(i1)
	f2 *= @int_to_float(i2)

	if i1 > 0 return 1
	if i2 > 0 return 2

	if f1 > 0.0 return 3
	if f1 > 0.0 return 4

	return 0
}
