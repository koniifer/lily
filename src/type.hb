// RawKind := enum {
// 	.Builtin;
// 	.Pointer;
// 	.SliceOrArray;
// 	.Optional;
// 	.Tuple;
// 	.Enum;
// 	.Union;
// 	.Struct;
// 	.IdkWhatThisIs;
// 	.Function;
// }

// Kind := enum {
// 	.Builtin;
// 	.Pointer;
// 	.Slice;
// 	.Array;
// 	.Optional;
// 	.Tuple;
// 	.Enum;
// 	.Union;
// 	.Struct;
// 	.IdkWhatThisIs;
// 	.Function;
// }

TypeOf := fn(v: @Any()): type return Type(@TypeOf(v))

Type := fn($T: type): type return struct {
	USize := fn(): type {
		if @size_of(T) == 0 @error(T, "(size=", @size_of(T), ")", "is too small to fit into an integer.")
		if @size_of(T) == 1 return u8 else if @size_of(T) == 2 return u16 else if @size_of(T) <= 4 return u32 else if @size_of(T) <= 8 return uint else @error(T, "(size=", @size_of(T), ")", "is too big to fit into an integer.")
	}
	Child := fn(): type {
		return Type(@ChildOf(T))
	}
	This := fn(): type {
		return T
	}
	$name := fn(): []u8 {
		return @name_of(T)
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
		return @CurrentScope().is_unsigned_int() | @CurrentScope().is_signed_int()
	}
	$is_float := fn(): bool {
		return T == f32 | T == f64
	}
	$len := fn(): uint {
		return @len_of(T)
	}
	$align := fn(): uint {
		return @align_of(T)
	}
	$size := fn(): uint {
		return @size_of(T)
	}
	$bits := fn(): @CurrentScope().USize() {
		return @size_of(T) << 3
	}
	$bitmask := fn(): @CurrentScope().USize() {
		return ~0
	}
	// $raw_kind := fn(): RawKind {
	// 	return @bit_cast(@kind_of(T))
	// }
	// $kind := fn(): Kind {
	// 	match Type(T).raw_kind() {
	// 		.SliceOrArray => if []@ChildOf(T) == T return .Slice else return .Array,
	// 		_ => if Type(T).raw_kind() > RawKind.SliceOrArray {
	// 				return @bit_cast(@kind_of(T) + 1)
	// 			}
	// 			return @bit_cast(Type(T).raw_kind())
	// 		},
	// 	}
	// }
}
