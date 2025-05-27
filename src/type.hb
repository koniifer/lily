RawKind := enum {
	.Builtin;
	.Pointer;
	.SliceOrArray;
	.Optional;
	.Tuple;
	.Enum;
	.Union;
	.Struct;
	.Template;
	.Function;
	.Global;
}

Kind := enum {
	.Builtin;
	.Pointer;
	.Slice;
	.Array;
	.Optional;
	.Tuple;
	.Enum;
	.Union;
	.Struct;
	.Template;
	.Function;
	.Global;
}

TypeInfo := fn($T: type): type return struct {
	Self := @CurrentScope()
	Child := TypeInfo(@ChildOf(T))
	Type := T
	UIntSize := UIntSizeOf(T)
	IntSize := IntSizeOf(T)

	$is_bool := T == bool
	$is_signed_int := T == i8 | T == i16 | T == i32 | T == i64 | T == int
	$is_unsigned_int := T == u8 | T == u16 | T == u32 | T == u64 | T == uint
	$is_float := T == f32 | T == f64
	$is_int := is_signed_int | is_unsigned_int
	$is_signed := is_float | is_signed_int

	$bitmask: UIntSize = ~0
	$max := max_of(T)
	$min := min_of(T)

	$name := @name_of(T)
	$len := @len_of(T)
	$offset := @align_of(T)
	$size := @size_of(T)
	$bits := Self.size << 3
	$raw_kind: RawKind = @bit_cast(@kind_of(T))
	$kind := kind_of(T)
}

max_of := fn($T: type): T {
	$if T == bool return true

	$if TypeInfo(T).is_unsigned_int return ~0
	$if TypeInfo(T).is_signed_int return @bit_cast(TypeInfo(T).bitmask >> 1)

	$if T == f32 return @bit_cast(@as(u32, 0x7F7FFFFF))
	$if T == f64 return @bit_cast(@as(u64, 0x7FEFFFFFFFFFFFFF))

	@error(T, " does not have a meaningful maximum value")
}

min_of := fn($T: type): T {
	$if T == bool return false

	$if TypeInfo(T).is_unsigned_int return 0
	$if TypeInfo(T).is_signed_int return ~@bit_cast(TypeInfo(T).bitmask >> 1)

	$if T == f32 return @bit_cast(@as(u32, 0xFF7FFFFF))
	$if T == f64 return @bit_cast(@as(u64, 0xFFEFFFFFFFFFFFFF))

	@error(T, " does not have a meaningful minimum value")
}

UIntSizeOf := fn($T: type): type {
	$U := never

	$if @size_of(T) == 0 @error(T, " has size 0.")
	$if @size_of(T) <= 8 U = u64 else @error(T, " is too large to fit into an integer.")
	$if @size_of(T) <= 4 U = u32
	$if @size_of(T) == 2 U = u16
	$if @size_of(T) == 1 U = u8

	$if @size_of(U) == @size_of(uint) return uint
	return U
}

IntSizeOf := fn($T: type): type {
	$I := never

	$if @size_of(T) == 0 @error(T, " has size 0.")
	$if @size_of(T) <= 8 I = i64 else @error(T, " is too large to fit into an integer.")
	$if @size_of(T) <= 4 I = i32
	$if @size_of(T) == 2 I = i16
	$if @size_of(T) == 1 I = i8

	$if @size_of(I) == @size_of(int) return int
	return I
}

$kind_of := fn($T: type): Kind {
	$match @as(RawKind, @bit_cast(@kind_of(T))) {
		.SliceOrArray => $if []@ChildOf(T) == T return .Slice else return .Array,
		_ => $if @kind_of(T) > @bit_cast(RawKind.SliceOrArray) {
			return @bit_cast(@kind_of(T) + 1)
		} else return @bit_cast(@kind_of(T)),
	}
}
