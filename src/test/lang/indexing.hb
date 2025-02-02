/*
 * exit: 0
*/

index := fn(buf: @Any()): u8 {
	b := buf[0]
	buf[0] = 1
	return b
}

main := fn(): u8 {
	_ = @inline(index, u8.[0, 0, 0])
	_ = @inline(index, u8.[0, 0, 0][0..3])
	_ = index(u8.[0, 0, 0])
	// ! (libc) (compiler) bug: index_opaque([]T) causes compiler panic
	_ = index(u8.[0, 0, 0][0..3])
	return 0
}