expectations := .{
	return_value: 0,
}

generic := fn(v: @Any()): uint {
	if @TypeOf(v) == uint {
		return 1
	}
	return 0
}

main := fn(): uint {
	a := generic(0)
	b := generic(@as(int, 0))
	if a != 1 return 1
	if b != 0 return 1
	return 0
}
