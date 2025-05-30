expectations := .{
	return_value: 0,
}

lily.{mem} := @use("../../src/lib.hb")

main := fn(): uint {
	if mem.forward_align(@as(^u8, @bit_cast(101)), 5) != @bit_cast(105) return 1
	if mem.backward_align(@as(^u8, @bit_cast(101)), 5) != @bit_cast(100) return 2
	if mem.forward_align_pow2(@as(^u8, @bit_cast(101)), 8) != @bit_cast(104) return 3
	if mem.backward_align_pow2(@as(^u8, @bit_cast(101)), 8) != @bit_cast(96) return 4

	if !mem.is_aligned(@as(^u8, @bit_cast(104)), 8) return 5

	return 0
}
