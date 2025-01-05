.{target, Type, TypeOf, string, memcpy} := @use("lib.hb")

// ! (c_native) (compiler) bug: caused by: `lily.log.print(100)`
fmt_int := fn(v: @Any(), str: []u8, radix: @TypeOf(v)): uint {
	is_negative := TypeOf(v).is_signed_int() & v < 0
	prefix_len := 0
	if is_negative {
		v = -v
		str[0] = '-'
		prefix_len += 1
	}

	if radix == 16 {
		*@as(^[2]u8, @bitcast(str.ptr + prefix_len)) = *@bitcast("0x".ptr)
		prefix_len += 2
	} else if radix == 2 {
		*@as(^[2]u8, @bitcast(str.ptr + prefix_len)) = *@bitcast("0b".ptr)
		prefix_len += 2
	} else if radix == 8 {
		*@as(^[2]u8, @bitcast(str.ptr + prefix_len)) = *@bitcast("0o".ptr)
		prefix_len += 2
	}

	if v == 0 {
		str[prefix_len] = '0'
		return prefix_len + 1
	}

	i := prefix_len
	loop if v <= 0 break else {
		remainder := v % radix
		v /= radix
		if remainder > 9 {
			str[i] = @intcast(remainder - 10 + 'A')
		} else {
			str[i] = @intcast(remainder + '0')
		}
		i += 1
	}

	string.reverse(str[prefix_len..i])
	return i
}

fmt_bool := fn(v: bool, str: []u8): uint {
	if v {
		memcpy(str.ptr, "true".ptr, 4)
		return 4
	} else {
		memcpy(str.ptr, "false".ptr, 5)
		return 5
	}
}

format := fn(buf: []u8, v: @Any()): uint {
	T := TypeOf(v)
	match T.kind() {
		.Pointer => return fmt_int(@as(uint, @bitcast(v)), buf, 16),
		.Builtin => {
			if T.is_int() return fmt_int(v, buf, 10)
			if T.is_bool() return fmt_bool(v, buf)
		},
		_ => @error("format(", T, ") is not supported."),
	}
	return 0
}

format_with_str := fn(str: []u8, buf: []u8, v: @Any()): uint {
	memcpy(buf.ptr, str.ptr, str.len)
	return str.len
}