Version := struct {
	major: uint,
	minor: uint,
	patch: uint,
}

$VERSION := Version(0, 0, 6)

Config := struct {
	$DEBUG := true
	$DEBUG_ASSERTIONS := false
	$MIN_LOGLEVEL := log.LogLevel.Info

	$debug := fn(): bool return Config.DEBUG
	$debug_assertions := fn(): bool return Config.DEBUG | Config.DEBUG_ASSERTIONS
	$min_loglevel := fn(): log.LogLevel {
		if Config.debug() & Config.MIN_LOGLEVEL < .Debug return .Debug
		return Config.MIN_LOGLEVEL
	}
}

// ----------------------------------------------------

collections := @use("collections/lib.hb")
result := @use("result.hb")
string := @use("string.hb")
alloc := @use("alloc/lib.hb")
hash := @use("hash/lib.hb")
rand := @use("rand/lib.hb")
math := @use("math.hb")
iter := @use("iter.hb")
log := @use("log.hb")
fmt := @use("fmt.hb");

.{Target} := @use("targets/lib.hb");
.{print, printf} := log;
.{Type, TypeOf} := @use("type.hb")

// ! (compiler) bug: inlining here crashes the parser. nice.
// ! (libc) (compiler) bug: NOT inlining here makes it sometimes not work
$panic := fn(message: ?[]u8): never {
	if message != null log.error(message) else log.error("The program called panic.")
	exit(1)
}

// ! exit, memcpy, memmove, and memset are all temporary wrapper functions
$exit := fn(code: int): never {
	Target.exit_w(code)
	die
}

$memcpy := fn(dest: @Any(), src: @Any(), size: uint): void {
	if TypeOf(dest).kind() != .Pointer | TypeOf(src).kind() != .Pointer @error("memcpy requires a pointer")
	Target.memcpy_w(@bitcast(dest), @bitcast(src), size)
}

$memmove := fn(dest: @Any(), src: @Any(), size: uint): void {
	if TypeOf(dest).kind() != .Pointer | TypeOf(src).kind() != .Pointer @error("memmove requires a pointer")
	Target.memmove_w(@bitcast(dest), @bitcast(src), size)
}

$memset := fn(dest: @Any(), src: u8, size: uint): void {
	if TypeOf(dest).kind() != .Pointer @error("memset requires a pointer")
	Target.memset_w(@bitcast(dest), src, size)
}

_qs_partition := fn($func: type, array: @Any(), start: uint, end: uint): uint {
	pivot := array[end]
	i := start
	j := start
	loop if j >= end break else {
		defer j += 1
		if func(array[j], pivot) {
			temp := array[i]
			array[i] = array[j]
			array[j] = temp
			i += 1
		}
	}
	temp := array[i]
	array[i] = array[end]
	array[end] = temp
	return i
}

/// Can sort in place if `&array` is passed rather than `array`
/// For sorting slices in place, do not pass `&slice`, pass `slice` instead.
quicksort := fn($func: type, array: @Any(), start: uint, end: uint): @TypeOf(array) {
	if start >= end return array;
	pivot_index := _qs_partition(func, array, start, end)
	if pivot_index > 0 array = quicksort(func, array, start, pivot_index - 1)
	array = quicksort(func, array, pivot_index + 1, end)
	return array
}

$compare := fn(lhs: @Any(), rhs: @Any()): bool {
	return lhs < rhs
}