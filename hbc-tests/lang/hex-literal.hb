expectations := .{
	return_value: 0,
}

hex := fn(): uint return 0x2D
dec := fn(): uint return 45

main := fn(): uint {
	if hex() != dec() return 1
	return 0
}
