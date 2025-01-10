.{TypeOf} := @use("lib.hb")

// ! possibly little endian only.
// ! should be fixed if we rely on libc for math
// ! ableos is always little endian so no big deal.

$abs := fn(x: @Any()): @TypeOf(x) {
	T := TypeOf(x)
	if T.is_int() return (x ^ x >> @bitcast(T.bits()) - 1) - (x >> @bitcast(T.bits()) - 1)
	if T.is_float() return @bitcast(@as(T.USize(), @bitcast(x)) & T.bitmask() >> 1)
	@error("lily.math.abs only supports integers and floats.")
}

// todo: better float min, max
$min := fn(a: @Any(), b: @TypeOf(a)): @TypeOf(a) {
	T := TypeOf(a)
	if T.is_int() return b + (a - b & a - b >> @bitcast(T.bits()) - 1)
	if T.is_float() return @itf(a > b) * b + @itf(a <= b) * a
}
$max := fn(a: @Any(), b: @TypeOf(a)): @TypeOf(a) {
	T := TypeOf(a)
	if T.is_int() return a - (a - b & a - b >> @bitcast(T.bits()) - 1)
	if T.is_float() return @itf(a > b) * a + @itf(a <= b) * b
}
$clamp := fn(x: @Any(), minimum: @TypeOf(x), maximum: @TypeOf(x)): @TypeOf(x) {
	return max(min(x, maximum), minimum)
}