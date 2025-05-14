.{target, Type, TypeOf, mem} := @use("lib.hb")

fmt_int := fn(buf: []u8, v: @Any(), radix: @TypeOf(v)): uint {
	if radix == 0 {
		mem.copy(buf, mem.as_bytes(&v))
		return @size_of(@TypeOf(v))
	}

	prefix_len := 0
	if Type(@TypeOf(v)).is_signed_int() & v < 0 {
		v = -v
		buf[0] = '-'
		prefix_len += 1
	}
	if radix == 16 {
		mem.copy(buf[prefix_len..], "0x")
		prefix_len += 2
	} else if radix == 8 {
		mem.copy(buf[prefix_len..], "0o")
		prefix_len += 2
	} else if radix == 2 {
		mem.copy(buf[prefix_len..], "0b")
		prefix_len += 2
	}

	if v == 0 {
		buf[prefix_len] = '0'
		return prefix_len + 1
	}

	i := prefix_len
	loop if v <= 0 break else {
		remainder := v % radix
		v /= radix
		if remainder > 9 {
			buf[i] = @int_cast(remainder - 10 + 'A')
		} else {
			buf[i] = @int_cast(remainder + '0')
		}
		i += 1
	}
	_ = mem.reverse(buf[prefix_len..i])
	return i
}

fmt_bool := fn(buf: []u8, v: bool): uint {
	if v {
		mem.copy(buf, "true")
		return 4
	} else {
		mem.copy(buf, "false")
		return 5
	}
}

fmt_optional := fn(buf: []u8, v: @Any()): uint {
	if v != null return format(buf, @as(@ChildOf(@TypeOf(v)), v.?))
	mem.copy(buf, "null")
	return 4
}

// todo: cleanup
fmt_enum := fn(buf: []u8, v: @Any()): uint {
	T := @TypeOf(v)
	len := @name_of(T).len
	mem.copy(buf, @name_of(T))
	mem.copy(buf[len..], ".(")
	len += 2
	len += fmt_int(buf[len..], @as(Type(T).USize(), @bit_cast(v)), 10)
	mem.copy(buf[len..], ")")
	return len + 1
}

format := fn(buf: []u8, v: @Any()): uint {
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
