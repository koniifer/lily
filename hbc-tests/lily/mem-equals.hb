expectations := .{
	return_value: 0,
}

lily.{mem} := @use("../../src/lib.hb")

main := fn(): uint {
	abc := "abc"
	a_b_c := u8.['a', 'b', 'c'][..]
	if !mem.equals(abc, abc) return 1
	if !mem.equals(a_b_c, abc) return 1

	return 0
}
