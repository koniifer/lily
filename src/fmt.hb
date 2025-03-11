.{target, Type, TypeOf, mem} := @use("lib.hb")

fmt_int := fn(buf: []u8, v: @Any(), radix: @TypeOf(v)): uint {
	if radix == 0 {
		mem.copy(buf.ptr, @bit_cast(&v), @size_of(@TypeOf(v)))
		return @size_of(@TypeOf(v))
	}

	prefix_len := 0
	if Type(@TypeOf(v)).is_signed_int() & v < 0 {
		v = -v
		// 0x2D == '-'
		buf[0] = 0x2D
		prefix_len += 1
	}
	if radix == 16 {
		mem.copy(buf.ptr + prefix_len, "0x".ptr, 2)
		prefix_len += 2
	} else if radix == 8 {
		mem.copy(buf.ptr + prefix_len, "0o".ptr, 2)
		prefix_len += 2
	} else if radix == 2 {
		mem.copy(buf.ptr + prefix_len, "0b".ptr, 2)
		prefix_len += 2
	}

	if v == 0 {
		// 0x30 == '0'
		buf[prefix_len] = 0x30
		return prefix_len + 1
	}

	i := prefix_len
	loop if v <= 0 break else {
		remainder := v % radix
		v /= radix
		if remainder > 9 {
			// 0x41 == 'A'
			buf[i] = @int_cast(remainder - 10 + 0x41)
		} else {
			// 0x30 == '0'
			buf[i] = @int_cast(remainder + 0x30)
		}
		i += 1
	}
	_ = mem.reverse(buf[prefix_len..i])
	return i
}

fmt_bool := fn(buf: []u8, v: bool): uint {
	if v {
		mem.copy(buf.ptr, "true".ptr, 4)
		return 4
	} else {
		mem.copy(buf.ptr, "false".ptr, 5)
		return 5
	}
}

fmt_optional := fn(buf: []u8, v: @Any()): uint {
	if v != null return format(buf, @as(@ChildOf(@TypeOf(v)), v.?))

	mem.copy(buf.ptr, @name_of(@TypeOf(v)).ptr, @name_of(@TypeOf(v)).len)
	mem.copy(buf.ptr + @name_of(@TypeOf(v)).len, ".null".ptr, 5)
	return @name_of(@TypeOf(v)).len + 5
}

// todo: cleanup
fmt_enum := fn(buf: []u8, v: @Any()): uint {
	T := @TypeOf(v)
	len := @name_of(T).len
	mem.copy(buf.ptr, @name_of(T).ptr, len)
	mem.copy(buf.ptr + len, ".(".ptr, 2)
	len += 2
	len += fmt_int(buf[len..], @as(Type(T).USize(), @bit_cast(v)), 10)
	mem.copy(buf.ptr + len, ")".ptr, 1)
	return len + 1
}

format := fn(buf: []u8, v: @Any()): uint {
	// $T := TypeOf(v)
	T := Type(@TypeOf(v))
	$match T.kind() {
		.Pointer => return fmt_int(buf, @as(uint, @bit_cast(v)), 16),
		.Builtin => {
			$if T.is_int() return fmt_int(buf, v, 10)
			$if T.is_bool() return fmt_bool(buf, v)
			$if T.is_float() @error("todo: fmt_float")
		},
		.Struct => @error("todo: fmt_container"),
		.Tuple => @error("todo: fmt_container"),
		.Slice => @error("todo: fmt_container"),
		.Array => @error("todo: fmt_container"),
		.Optional => return fmt_optional(buf, v),
		.Enum => return fmt_enum(buf, v),
		_ => @error("formatting ", @TypeOf(v), " is not supported"),
	}
}
