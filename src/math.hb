lily.{config, TypeInfo} := @use("lib.hb")

// stuff in this file is temporary. did not have anywhere to put it.

$int_is_power_of_two_or_zero := fn(x: @Any()): bool {
	$if !TypeInfo(@TypeOf(x)).is_int {
		@error("unsupported type: ", @TypeOf(x))
	}
	return (x & x - 1) == 0
}

$int_is_power_of_two := fn(x: @Any()): bool {
	return int_is_power_of_two_or_zero(x) & x != 0
}

$int_one_less_than_next_power_of_two := fn(x: @Any()): @TypeOf(x) {
	$if !TypeInfo(@TypeOf(x)).is_int {
		@error("unsupported type: ", @TypeOf(x))
	}
	x -= x != 0
	$i: @TypeOf(x) = 1
	$loop $if i == @size_of(@TypeOf(x)) * 8 break else {
		x |= x >> i
		i *= 2
	}
	return x
}

$int_next_power_of_two := fn(x: @Any()): @TypeOf(x) {
	return int_one_less_than_next_power_of_two(x) + 1
}
