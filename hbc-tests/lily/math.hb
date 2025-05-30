expectations := .{
	return_value: 0,
}

lily.{math} := @use("../../src/lib.hb")

main := fn(): uint {
	if math.int_is_power_of_two_or_zero(3) return 1
	if !math.int_is_power_of_two_or_zero(0) return 2
	if !math.int_is_power_of_two_or_zero(2) return 3
	if math.int_is_power_of_two(3) return 4
	if math.int_is_power_of_two(0) return 5
	if !math.int_is_power_of_two(2) return 6

	if math.int_one_less_than_next_power_of_two(0) != 0 return 7
	if math.int_next_power_of_two(65) != 128 return 8
	return 0
}
