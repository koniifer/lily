.{target, iter: .{Iterator, Next}, config, log, TypeInfo} := @use("lib.hb")

$size := fn($T: type, count: uint): uint {
	return @size_of(T) * count
}

/// safety: assumes align != 0
$forward_align := fn(ptr: ^u8, _align: uint): ^u8 {
	return @bit_cast((@bit_cast(ptr) + _align - 1) / _align * _align)
}

/// safety: assumes align != 0
$backward_align := fn(ptr: ^u8, _align: uint): ^u8 {
	return @bit_cast(@bit_cast(ptr) / _align * _align)
}

$is_aligned := fn(ptr: ^u8, _align: uint): bool {
	return @bit_cast(ptr) % _align == 0
}

$dangling := fn($T: type): ^T {
	$if TypeInfo(T).kind == .Optional @error(T, " is an optional pointer. use `null` instead.")
	return @bit_cast(@align_of(T))
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
	$if config.DEBUG {
		if src.len > dest.len | overlaps(dest, src) {
			log.error("mem.copy: regions overlap or src bigger than dest")
			die
		}
	}
	target.memcopy(dest.ptr, src.ptr, src.len)
}

$move := fn(dest: []u8, src: []u8): void {
	$if config.DEBUG {
		if src.len > dest.len {
			log.error("mem.move: src bigger than dest")
			die
		}
	}
	target.memmove(dest.ptr, src.ptr, src.len)
}

$set := fn(dest: []u8, src: u8): void {
	target.memset(dest.ptr, src, dest.len)
}

$fill := fn(dest: []u8, src: []u8): void {
	$if config.DEBUG {
		if src.len > dest.len | overlaps(dest, src) {
			log.error("mem.copy: regions overlap or src bigger than dest")
			die
		}
	}
	target.memfill(dest.ptr, src.ptr, dest.len / src.len, src.len)
}

equals := fn(lhs: []u8, rhs: []u8): bool {
	if lhs.len != rhs.len return false
	if lhs.ptr == rhs.ptr return true
	i := 0
	loop if i == lhs.len break else {
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
