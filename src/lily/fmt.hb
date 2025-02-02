.{target, Type, TypeOf, string, memcopy, panic} := @use("lib.hb")

$FP_TOLERANCE := 0.00000001

// ! (libc) (compiler) bug: caused by: `lily.log.print(100)`
fmt_int := fn(buf: []u8, v: @Any(), radix: @TypeOf(v)): uint {
	prefix_len := 0
	if TypeOf(v).is_signed_int() & v < 0 {
		v = -v
		buf[0] = '-'
		prefix_len += 1
	}

	if radix == 16 {
		memcopy(buf.ptr + prefix_len, "0x".ptr, 2)
		prefix_len += 2
	} else if radix == 2 {
		memcopy(buf.ptr + prefix_len, "0b".ptr, 2)
		prefix_len += 2
	} else if radix == 8 {
		memcopy(buf.ptr + prefix_len, "0o".ptr, 2)
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
		// ! (libc) workaround for compiler bug
		// if remainder > 9 {
		// 	buf[i] = @intcast(remainder - 10 + 'A')
		// } else {
		// 	buf[i] = @intcast(remainder + '0')
		// }
		if remainder > 9 {
			remainder += 'A' - 10
		} else {
			remainder += '0'
		}
		buf[i] = @intcast(remainder)
		i += 1
	}

	string.reverse(buf[prefix_len..i])
	return i
}

// ! (libc) (compiler) keeps complaining about 'not yet implemented' only on libc
fmt_float := fn(buf: []u8, v: @Any(), precision: uint, radix: int): uint {
	prefix_len := 0

	if v < 0 {
		v = -v
		buf[0] = '-'
		prefix_len += 1
	}

	if radix == 16 {
		memcopy(buf.ptr + prefix_len, "0x".ptr, 2)
		prefix_len += 2
	} else if radix == 2 {
		memcopy(buf.ptr + prefix_len, "0b".ptr, 2)
		prefix_len += 2
	} else if radix == 8 {
		memcopy(buf.ptr + prefix_len, "0o".ptr, 2)
		prefix_len += 2
	}

	integer_part := @fti(v)
	fractional_part := v - @itf(integer_part)

	i := prefix_len
	loop if integer_part == 0 & i > prefix_len break else {
		remainder := integer_part % radix
		integer_part /= radix
		if remainder > 9 {
			buf[i] = @intcast(remainder - 10 + 'A')
		} else {
			buf[i] = @intcast(remainder + '0')
		}
		i += 1
	}

	string.reverse(buf[prefix_len..i])
	if fractional_part > FP_TOLERANCE {
		buf[i] = '.'
		i += 1

		p := precision
		loop if p <= 0 | fractional_part < FP_TOLERANCE break else {
			fractional_part *= @itf(radix)
			digit := @fti(fractional_part)
			if digit > 9 {
				buf[i] = @intcast(digit - 10 + 'A')
			} else {
				buf[i] = @intcast(digit + '0')
			}
			i += 1
			fractional_part -= @itf(digit)
			p -= 1
		}
	}
	return i
}

fmt_bool := fn(buf: []u8, v: bool): uint {
	if v {
		memcopy(buf.ptr, "true".ptr, 4)
		return 4
	} else {
		memcopy(buf.ptr, "false".ptr, 5)
		return 5
	}
}

fmt_container := fn(buf: []u8, v: @Any()): uint {
	T := TypeOf(v)
	i := 0
	len := 0
	if T.kind() == .Struct {
		memcopy(buf.ptr + len, T.name().ptr, T.name().len)
		len += T.name().len
		memcopy(buf.ptr + len, ".(".ptr, 2)
		len += 2
	} else if T.kind() == .Slice | T.kind() == .Array {
		memcopy(buf.ptr + len, T.Child().name().ptr, T.Child().name().len)
		len += T.Child().name().len
		memcopy(buf.ptr + len, ".[".ptr, 2)
		len += 2
	} else if T.kind() == .Tuple {
		memcopy(buf.ptr + len, ".(".ptr, 2)
		len += 2
	}

	if T.kind() == .Slice {
		loop if i == v.len break else {
			len += format(buf[len..], v[i])
			i += 1
			if i < v.len {
				memcopy(buf.ptr + len, ", ".ptr, 2)
				len += 2
			}
		}
	} else {
		$loop if i == T.len() break else {
			len += format(buf[len..], v[i])
			i += 1
			if i < T.len() {
				memcopy(buf.ptr + len, ", ".ptr, 2)
				len += 2
			}
		}
	}

	if T.kind() == .Struct | T.kind() == .Tuple {
		*(buf.ptr + len) = ')'
		len += 1
	} else if T.kind() == .Slice | T.kind() == .Array {
		*(buf.ptr + len) = ']'
		len += 1
	}
	return len
}

fmt_optional := fn(buf: []u8, v: @Any()): uint {
	if v != null return format(buf, @as(@ChildOf(@TypeOf(v)), v))

	memcopy(buf.ptr, @nameof(@TypeOf(v)).ptr, @nameof(@TypeOf(v)).len)
	memcopy(buf.ptr + @nameof(@TypeOf(v)).len, ".null".ptr, 5)
	return @nameof(@TypeOf(v)).len + 5
}

// todo: clean up this and other functions
fmt_enum := fn(buf: []u8, v: @Any()): uint {
	T := @TypeOf(v)
	len := @nameof(T).len;
	memcopy(buf.ptr, @nameof(T).ptr, len)
	memcopy(buf.ptr + len, ".(".ptr, 2)
	len += 2
	len += fmt_int(buf[len..], @as(Type(T).USize(), @bitcast(v)), 10);
	memcopy(buf.ptr + len, ")".ptr, 1)
	return len + 1
}

format := fn(buf: []u8, v: @Any()): uint {
	T := TypeOf(v)
	match T.kind() {
		.Pointer => return fmt_int(buf, @as(uint, @bitcast(v)), 16),
		.Builtin => {
			if T.is_int() return fmt_int(buf, v, 10)
			if T.is_bool() return fmt_bool(buf, v)
			if T.is_float() return fmt_float(buf, v, 1 << 32, 10)
		},
		.Struct => return fmt_container(buf, v),
		.Tuple => return fmt_container(buf, v),
		.Slice => {
			if T.This() == []u8 {
				*buf.ptr = '"'
				memcopy(buf.ptr + 1, v.ptr, v.len);
				*(buf.ptr + 1 + v.len) = '"'
				return v.len + 2
			}
			return fmt_container(buf, v)
		},
		.Array => return fmt_container(buf, v),
		.Optional => return fmt_optional(buf, v),
		.Enum => return fmt_enum(buf, v),
		_ => @error("format(", T, ") is not supported."),
	}
	return 0
}

// ! (compiler) bug: panic doesnt work here specifically. causes parser issue.
format_with_str := fn(str: []u8, buf: []u8, v: @Any()): uint {
	T := TypeOf(v)
	n := string.count(str, '{')
	// if n != string.count(str, '}') panic("Missing closing '}' in format string.")
	if n != string.count(str, '}') die
	if T.kind() == .Tuple {
		// if T.len() != n panic("Format string has different number of '{}' than args given.")
		if T.len() != n die
		m := 0
		i := 0
		j := 0
		$loop if m > T.len() break else {
			if m == T.len() {
				loop if i == str.len break else {
					buf[j] = str[i]
					i += 1
					j += 1
				}
				m += 1
			} else {
				v2 := v[m]
				loop if i == str.len break else {
					if str[i] == '{' & str[i + 1] == '}' {
						j += format(buf[j..], v2)
						i += 2
						break
					} else {
						buf[j] = str[i]
						i += 1
						j += 1
					}
				}
				m += 1
			}
		}
		return j
	} else if n > 1 {
		// panic("Format string has multiple '{}' but value provided is not a tuple.")
		die
	} else {
		i := 0
		j := 0
		loop if i == str.len break else {
			if str[i] == '{' & str[i + 1] == '}' {
				j += format(buf[j..], v)
				i += 2
			} else {
				buf[j] = str[i]
				i += 1
				j += 1
			}
		}
		return j
	}
}