Version := struct {
	major: uint,
	minor: uint,
	patch: uint,
}

$VERSION := Version(0, 0, 2)

collections := @use("collections/lib.hb")
result := @use("result.hb")
alloc := @use("alloc.hb")
log := @use("log.hb")

target_c_native := @use("target/c_native.hb")
target_hbvm_ableos := @use("target/hbvm_ableos.hb")
// target := target_hbvm_ableos
target := target_c_native

$exit := fn(code: int): void {
	_ = target.exit(code)
	die
}

Kind := enum {
	Builtin,
	Struct,
	Tuple,
	Enum,
	Union,
	Pointer,
	Slice,
	Opt,
	Function,
	Template,
	Global,
	Const,
	Module,
}

$null_pointer := fn($T: type): ^T return @bitcast(0)

Type := fn($T: type): type return struct {
	$is_unsigned_int := fn(): bool {
		return T == uint | T == u8 | T == u16 | T == u32
	}
	$is_signed_int := fn(): bool {
		return T == int | T == i8 | T == i16 | T == i32
	}
	$is_int := fn(): bool {
		return Self.unsigned_int(T) | Self.signed_int(T)
	}
	$is_float := fn(): bool {
		return T == f32 | T == f64
	}
	$usize := fn(): type {
		if @sizeof(T) == 1 return u8 else if @sizeof(T) == 2 return u16 else if @sizeof(T) == 4 return u32 else return uint
	}
	$bits := fn(): Self.usize() {
		return @sizeof(T) << 3
	}
	$bitmask := fn(): Self.usize() {
		return -1
	}
	$kind := fn(): Kind {
		return @bitcast(@kindof(T))
	}
}