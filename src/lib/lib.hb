Version := struct {
	major: uint,
	minor: uint,
	patch: uint,
}

$VERSION := Version(0, 0, 3)

collections := @use("collections/lib.hb")
result := @use("result.hb")
string := @use("string.hb")
alloc := @use("alloc.hb")
rand := @use("rand.hb")
log := @use("log.hb")
fmt := @use("fmt.hb")

target_hbvm_ableos := @use("target/hbvm_ableos.hb")
target_c_native := @use("target/c_native.hb");
.{DEBUG, target} := @use("target/config.hb")

// ! exit, memcpy, memmove, and memset are all temporary wrapper functions

$exit := fn(code: int): never {
	target.exit(code)
	die
}

// ! (compiler) bug: inlining here crashes the parser. nice.
// ! (c_native) (compiler) bug: NOT inlining here makes it sometimes not work
$panic := fn(message: ?[]u8): never {
	if message != null log.error(message) else log.error("The program called panic.")
	exit(1)
}

$memcpy := fn(dest: @Any(), src: @Any(), size: uint): void {
	if TypeOf(dest).kind() != .Pointer | TypeOf(src).kind() != .Pointer @error("memcpy requires a pointer")
	target.memcpy(@bitcast(dest), @bitcast(src), size)
}

$memmove := fn(dest: @Any(), src: @Any(), size: uint): void {
	if TypeOf(dest).kind() != .Pointer | TypeOf(src).kind() != .Pointer @error("memmove requires a pointer")
	target.memmove(@bitcast(dest), @bitcast(src), size)
}

$memset := fn(dest: @Any(), src: u8, size: uint): void {
	if TypeOf(dest).kind() != .Pointer @error("memset requires a pointer")
	target.memset(@bitcast(dest), src, size)
}

RawKind := enum {
	Builtin,
	Struct,
	Tuple,
	Enum,
	Union,
	Pointer,
	Slice,
	Optional,
	Function,
	Template,
	Global,
	Constant,
	Module,
}

Kind := enum {
	Builtin,
	Struct,
	Tuple,
	Enum,
	Union,
	Pointer,
	Slice,
	Array,
	Optional,
	Function,
	Template,
	Global,
	Constant,
	Module,
}

TypeOf := fn(T: @Any()): type return Type(@TypeOf(T))

Type := fn($T: type): type return struct {
	// ! no way of representing arbitrary size integers yet
	USize := fn(): type {
		if @sizeof(T) == 1 return u8 else if @sizeof(T) == 2 return u16 else if @sizeof(T) == 4 return u32 else return uint
	}
	Child := fn(): type {
		return Type(@ChildOf(T))
	}
	This := fn(): type {
		return T
	}
	$name := fn(): []u8 {
		return @nameof(T)
	}
	$is_bool := fn(): bool {
		return T == bool
	}
	$is_unsigned_int := fn(): bool {
		return T == uint | T == u8 | T == u16 | T == u32
	}
	$is_signed_int := fn(): bool {
		return T == int | T == i8 | T == i16 | T == i32
	}
	$is_int := fn(): bool {
		return Self.is_unsigned_int() | Self.is_signed_int()
	}
	$is_float := fn(): bool {
		return T == f32 | T == f64
	}
	$len := fn(): uint {
		return @lenof(T)
	}
	$align := fn(): uint {
		return @alignof(T)
	}
	$size := fn(): uint {
		return @sizeof(T)
	}
	$bits := fn(): uint {
		return @sizeof(T) << 3
	}
	$bitmask := fn(): Self.Usize() {
		return -1
	}
	$raw_kind := fn(): RawKind {
		return @bitcast(@kindof(T))
	}
	$kind := fn(): Kind {
		if Self.raw_kind() == .Slice {
			if []@ChildOf(T) == T return .Slice else return .Array
		} else if @kindof(T) > @bitcast(Kind.Slice) {
			return @bitcast(@kindof(T) + 1)
		} else return @bitcast(Self.raw_kind())
	}
	/// ! There are no guarantees that this value is zeroed for builtins, enums, unions, structs, arrays, or tuples.
	$uninit := fn(): T {
		match Self.kind() {
			.Pointer => return @bitcast(0),
			.Slice => return @bitcast(@as(^void, @bitcast(0))[0..0]),
			.Array => return idk,
			.Builtin => return idk,
			.Struct => return idk,
			.Tuple => return idk,
			.Union => return idk,
			.Enum => return idk,
			.Optional => return null,
			_ => @error("Type(", T, ").uninit() does not make sense."),
		}
	}
}