lily.{target, iter: .{Iterator, Next}, config, TypeInfo, math} := @use("lib.hb")

$size := fn($T: type, count: uint): uint {
	return @size_of(T) * count
}

/// safety: assumes align is a power of 2
$forward_align := fn(ptr: ^u8, _align: uint): ^u8 {
	$if config.optimise < .ReleaseFast {
		if !math.int_is_power_of_two(_align) lily.panic("forward_align: align was not a power of 2")
	}
	return @bit_cast(@as(uint, @bit_cast(ptr)) + (_align - 1) & -_align)
}

/// safety: assumes align is a power of 2
$backward_align := fn(ptr: ^u8, _align: uint): ^u8 {
	$if config.optimise < .ReleaseFast {
		if !math.int_is_power_of_two(_align) lily.panic("backward_align: align was not a power of 2")
	}
	return @bit_cast(@as(uint, @bit_cast(ptr)) & -_align)
}

$is_aligned := fn(ptr: ^u8, _align: uint): bool {
	$if config.optimise < .ReleaseFast {
		if !math.int_is_power_of_two(_align) lily.panic("is_aligned: align was not a power of 2")
	}
	return (@as(uint, @bit_cast(ptr)) & _align - 1) == 0
}

// maybe return 0 ptr here if ReleaseFast
$dangling := fn($T: type): ^T {
	$if TypeInfo(T).kind == .Optional @error(T, " is an optional pointer. use `null` instead.")
	return @bit_cast(@align_of(T))
}

$is_dangling := fn(ptr: @Any()): bool {
	$if TypeInfo(@TypeOf(ptr)).kind != .Pointer @error(@TypeOf(ptr), " is not a pointer.")
	return ptr == @bit_cast(@align_of(@TypeOf(ptr)))
}

$as_bytes := fn(v: @Any()): []u8 {
	$T := @TypeOf(v)
	$match TypeInfo(T).kind {
		.Pointer => return @as(^u8, @bit_cast(v))[..@size_of(@ChildOf(T))],
		.Slice => return @as(^u8, @bit_cast(v.ptr))[..@size_of(@ChildOf(T)) * v.len],
		_ => @error(@TypeOf(v), " is not a pointer or a slice."),
	}
}

$to_owned := fn($T: type, slice: []u8): T {
	$match TypeInfo(T).kind {
		.Array => {
			$if config.optimise < .ReleaseFast {
				if @len_of(T) != slice.len lily.panic("to_owned: slice length did not match array length")
			}
			ret: T = idk
			copy(ret[..], slice)
			return ret
		},
		_ => @error("todo: write this error"),
	}
}

$overlaps := fn(lhs: []u8, rhs: []u8): bool {
	return lhs.ptr < rhs.ptr + rhs.len & rhs.ptr < lhs.ptr + lhs.len
}

$copy := fn(dest: []u8, src: []u8): void {
	$if config.optimise < .ReleaseFast {
		if src.len > dest.len | overlaps(dest, src) {
			lily.panic("mem.copy: regions overlap or src bigger than dest")
		}
	}
	target.memcopy(dest.ptr, src.ptr, src.len)
}

$move := fn(dest: []u8, src: []u8): void {
	$if config.optimise < .ReleaseFast {
		if src.len > dest.len {
			lily.panic("mem.move: src bigger than dest")
		}
	}
	target.memmove(dest.ptr, src.ptr, src.len)
}

$set := fn(dest: []u8, src: u8): void {
	target.memset(dest.ptr, src, dest.len)
}

$fill := fn(dest: []u8, src: []u8): void {
	$if config.optimise < .ReleaseFast {
		if src.len > dest.len | overlaps(dest, src) | dest.len % src.len != 0 {
			lily.panic("mem.copy: regions overlap or src bigger than dest, or dest won't perfectly tile src (end gap)")
		}
	}
	target.memfill(dest.ptr, src.ptr, dest.len / src.len, src.len)
}

equals := fn(lhs: []u8, rhs: []u8): bool {
	if lhs.len != rhs.len return false
	if lhs.ptr == rhs.ptr return true
	i := 0
	loop if i >= lhs.len | i >= rhs.len break else {
		if lhs[i] != rhs[i] return false
		i += 1
	}
	return true
}

reverse := fn(slice: []u8): []u8 {
	if slice.len == 0 return slice
	j := slice.len - 1
	i := 0
	temp: u8 = 0
	loop if i < j {
		temp = slice[i]
		slice[i] = slice[j]
		slice[j] = temp
		i += 1
		j -= 1
	} else return slice
}

count := fn(haystack: []u8, needle: @Any(), allow_overlaps: bool): uint {
	T := @TypeOf(needle)
	if haystack.len == 0 return 0
	i := 0
	c := 0
	$if T == []u8 {
		if needle.len == 0 return 0
		loop {
			if i + needle.len > haystack.len return c
			if haystack[i] == needle[0] {
				matches := true
				n := 1
				loop if n == needle.len break else {
					if haystack[i + n] != needle[n] {
						matches = false
						break
					}
					n += 1
				}
				if matches {
					c += 1
					if !allow_overlaps {
						i += needle.len
						continue
					}
				}
			}
			i += 1
		}
	} else $if T == u8 {
		loop {
			if i >= haystack.len return c
			if haystack[i] == needle c += 1
			i += 1
		}
	} else {
		@error("Type ", @TypeOf(needle), " is not []u8 or u8.")
	}
}

$iter := fn(slice: []u8): Iterator(struct {
	.slice: []u8

	$next := fn(self: ^@CurrentScope()): Next(u8) {
		tmp := Next(u8).(self.slice.len == 0, self.slice.ptr.*)
		self.slice = self.slice[1..]
		return tmp
	}
}) {
	return .(.(slice))
}
