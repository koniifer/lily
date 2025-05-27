lily.{TypeInfo, mem} := @use("lib.hb")

fmt_int := fn(buf: []u8, v: @Any(), radix: @TypeOf(v)): uint {
	if radix == 0 {
		mem.copy(buf, mem.as_bytes(&v))
		return @size_of(@TypeOf(v))
	}

	prefix_len := 0
	$if TypeInfo(@TypeOf(v)).is_signed_int {
		if v < 0 {
			// todo: handle edge case for int maximum negative value
			v = -v
			buf[0] = '-'
			prefix_len += 1
		}
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
		remainder: u8 = @int_cast(v % radix)
		v /= radix
		if remainder > 9 {
			buf[i] = remainder - 10 + 'A'
		} else {
			buf[i] = remainder + '0'
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
	if v != null {
		// have to bitcast here for some reason...
		v_real: @ChildOf(@TypeOf(v)) = @bit_cast(v.?)
		return format(buf, v_real)
	}
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
	len += fmt_int(buf[len..], @as(TypeInfo(T).UIntSize, @bit_cast(v)), 10)
	buf[len] = ')'
	return len + 1
}

fmt_container := fn(buf: []u8, v: @Any()): uint {
	T := TypeInfo(@TypeOf(v))
	i := 0
	len := 0
	$if T.kind == .Struct {
		// ! temporary workaround for segfault
		mem.copy(buf, @name_of(T.Type))
		len += T.name.len
		mem.copy(buf[len..], ".(")
	} else $if T.raw_kind == .SliceOrArray {
		// ! temporary workaround for segfault
		mem.copy(buf, @name_of(T.Child.Type))
		len += T.Child.name.len
		mem.copy(buf[len..], ".[")
	} else $if T.kind == .Tuple {
		// perhaps T.Child.name
		mem.copy(buf[len..], ".(")
	}
	len += 2

	$if T.kind == .Slice {
		loop if i == v.len break else {
			len += format(buf[len..], v[i])
			i += 1
			if i < v.len {
				mem.copy(buf[len..], ", ")
				len += 2
			}
		}
	} else {
		$loop $if i == T.len break else {
			len += format(buf[len..], v[i])
			i += 1
			$if i < T.len {
				// ! causing buffer overflow here (everywhere else too)
				// ! because buf[len..] reduces the length
				mem.copy(buf[len..], ", ")
				len += 2
			}
		}
	}

	$if T.kind == .Struct | T.kind == .Tuple {
		buf[len] = ')'
	} else {
		buf[len] = ']'
	}
	return len + 1
}

format := fn(buf: []u8, v: @Any()): uint {
	T := TypeInfo(@TypeOf(v))
	$match T.raw_kind {
		.Pointer => return fmt_int(buf, @as(uint, @bit_cast(v)), 16),
		.Builtin => {
			$if T.is_int return fmt_int(buf, v, 10)
			$if T.is_bool return fmt_bool(buf, v)
			$if T.is_float @error("todo: fmt_float")
		},
		.Struct => return fmt_container(buf, v),
		.Tuple => @error("cant format a tuple yet"),
		.SliceOrArray => return fmt_container(buf, v),
		.Optional => return fmt_optional(buf, v),
		.Enum => return fmt_enum(buf, v),
		_ => @error("formatting ", @TypeOf(v), " is not supported"),
	}
}
