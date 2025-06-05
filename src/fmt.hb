lily.{TypeInfo, mem} := @use("lib.hb")

fmt_int := fn(buf: []u8, v: @Any(), radix: @TypeOf(v)): uint {
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
			buf[i] = remainder - 10 + 'a'
		} else {
			buf[i] = remainder + '0'
		}
		i += 1
	}
	_ = mem.reverse(buf[prefix_len..i])
	return i
}

fmt_float := fn(buf: []u8, v: @Any(), precision: uint, radix: int): uint {
	prefix_len := 0
	if v < 0.0 {
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

	// todo: optimise unnecessary check
	if v == 0.0 {
		buf[prefix_len] = '0'
		return prefix_len + 1
	}

	integer_part := @float_to_int(v)
	fractional_part := v - @int_to_float(integer_part)

	i := prefix_len
	loop if integer_part <= 0 & i > prefix_len break else {
		remainder: u8 = @int_cast(integer_part % radix)
		integer_part /= radix
		if remainder > 9 {
			buf[i] = remainder - 10 + 'A'
		} else {
			buf[i] = remainder + '0'
		}
		i += 1
	}

	_ = mem.reverse(buf[prefix_len..i])
	if fractional_part > 0.000001 {
		buf[i] = '.'
		i += 1

		p := precision
		loop if p <= 0 | fractional_part < 0.000001 break else {
			fractional_part *= @int_to_float(radix)
			digit := @float_to_int(fractional_part)
			if digit > 9 {
				buf[i] = @int_cast(digit - 10 + 'a')
			} else {
				buf[i] = @int_cast(digit + '0')
			}
			i += 1
			p -= 1
			fractional_part -= @int_to_float(digit)
		}
	}
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
	buf[len] = '.'
	len += 1

	sum := 0
	i: u8 = 0
	$loop $if i == @len_of(@TypeOf(v)) break else {
		sum += @int_cast(@name_of(@as(@TypeOf(v), @bit_cast(i))).len)
		i += 1
	}

	namebuf: [sum]u8 = idk
	index: [@len_of(@TypeOf(v)) + 1]uint = idk

	index[0] = 0
	ii: u8 = 0
	bi := 0
	$loop $if ii == @len_of(@TypeOf(v)) break else {
		name := @name_of(@as(@TypeOf(v), @bit_cast(ii)))
		ij := 0
		$loop $if ij == name.len break else {
			namebuf[bi + ij] = name[ij]
			ij += 1
		}

		bi += @int_cast(name.len)
		ii += 1
		index[ii] = bi
	}

	mem.copy(buf[len..], namebuf[index[v]..index[@as(u8, v) + 1]])
	return len + namebuf[index[v]..index[@as(u8, v) + 1]].len
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
	} else $if T.internal_kind == .SliceOrArray {
		// ! temporary workaround for segfault
		mem.copy(buf, @name_of(T.Child.Type))
		len += T.Child.name.len
		mem.copy(buf[len..], ".[")
	} else $if T.kind == .Tuple {
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
	$if @has_decl(@TypeOf(v), "_fmt") return v._fmt(buf)

	T := TypeInfo(@TypeOf(v))
	$match T.internal_kind {
		.Pointer => return fmt_int(buf, @as(uint, @bit_cast(v)), 16),
		.Builtin => {
			$if T.is_int return fmt_int(buf, v, 10)
			$if T.is_bool return fmt_bool(buf, v)
			$if T.is_float return fmt_float(buf, v, 10, 10)

			@error("why are you trying to print a ", @TypeOf(v))
		},
		.Struct => return fmt_container(buf, v),
		.Tuple => return fmt_container(buf, v),
		.SliceOrArray => return fmt_container(buf, v),
		.Optional => return fmt_optional(buf, v),
		.Enum => return fmt_enum(buf, v),
		_ => @error("formatting ", @TypeOf(v), " is not supported"),
	}
}

format_with_str := fn(str: []u8, buf: []u8, v: @Any()): uint {
	T := TypeInfo(@TypeOf(v))
	$if T.kind != .Tuple @error(@TypeOf(v), " is not a tuple.")

	m := 0
	i := 0
	j := 0
	$loop $if m == T.len break else {
		v2 := v[m]
		loop if i == str.len break else {
			if str[i] == '{' {
				if str[i + 1] == '}' {
					j += format(buf[j..], v2)
					i += 2
				} else if str[i + 1] == 's' & str[i + 2] == '}' {
					$if @TypeOf(v2) == []u8 {
						mem.copy(buf[j..], v2)
						j += v2.len
						i += 3
					} else {
						lily.panic("cannot print value as a string")
					}
				}
				break
			} else {
				buf[j] = str[i]
				i += 1
				j += 1
			}
		}
		m += 1
	}
	mem.copy(buf[j..], str[i..])
	return j + str[i..].len
}
