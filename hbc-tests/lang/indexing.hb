expectations := .{
	return_value: 0,
}

index := fn(buf: @Any()): u8 {
	b := buf[0]
	buf[0] = 1
	return b
}

main := fn(): uint {
	_ = @inline(index, u8.[0, 0, 0])
	_ = @inline(index, u8.[0, 0, 0][0..3])
	_ = index(u8.[0, 0, 0])
	_ = index(u8.[0, 0, 0][0..3])
	return 0
}
