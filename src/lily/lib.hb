Version := struct {
	major: uint,
	minor: uint,
	patch: uint,
}

$VERSION := Version(0, 0, 4)

Config := struct {
	$DEBUG := false
	$DEBUG_ASSERTIONS := false
	$MIN_LOGLEVEL := log.LogLevel.Info

	$debug := fn(): bool return Config.DEBUG
	$debug_assertions := fn(): bool return Config.DEBUG | Config.DEBUG_ASSERTIONS
	$min_loglevel := fn(): log.LogLevel {
		if Config.debug() & Config.MIN_LOGLEVEL < .Debug return .Debug
		return Config.MIN_LOGLEVEL
	}
}

Target := enum {
	LibC,
	AbleOS,

	ableos := @use("targets/ableos.hb")
	libc := @use("targets/libc.hb")

	$current := fn(): Self {
		// This captures all HBVM targets, but for now only AbleOS is supported
		if @target("*-virt-unknown") {
			return .AbleOS
		}
		// Assume that unknown targets have libc
		return .LibC
	}
	$Lib := fn(self: Self): type {
		match self {
			.LibC => return Self.libc,
			.AbleOS => return Self.ableos,
		}
	}
	/* ! memmove, memcpy, memset, exit, currently suffixed with `_w` to distinguish them from the wrapper functions */;
	/* todo: reorganise these */;
	.{malloc, calloc, realloc, free, memmove: memmove_w, memcpy: memcpy_w, memset: memset_w, exit: exit_w, getrandom} := Self.Lib(Self.current());
	.{printf_str} := Self.Lib(.LibC);
	.{PAGE_SIZE, LogMsg} := Self.Lib(.AbleOS)
}

// ----------------------------------------------------

collections := @use("collections/lib.hb")
result := @use("result.hb")
string := @use("string.hb")
alloc := @use("alloc/lib.hb")
hash := @use("hash/lib.hb")
rand := @use("rand/lib.hb")
math := @use("math.hb")
log := @use("log.hb")
fmt := @use("fmt.hb");

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