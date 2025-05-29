expectations := .{
	return_value: 0,
}

find_niche := fn($T: type): ?struct {
	.pos: uint;
	.size: uint;
} {
	$if @kind_of(T) != 7 return {
	}

	offset := 0
	n := 0
	$loop $if n == @len_of(T) break else {
		field := @TypeOf(@as(T, idk)[n])
		// _field := &@as(T, idk)[n]
		// field := @ChildOf(@TypeOf(_field))

		field_a := @align_of(field)
		field_s := @size_of(field)
		aligned := align_forward(offset, field_a)

		$if aligned > offset {
			return .(offset, aligned - offset)
		}

		n += 1
		offset = aligned + field_s
	}

	$if offset < @size_of(T) {
		return .(offset, @size_of(T) - offset)
	}

	return null
}

X := struct {
	.a: uint;
	.b: u32;
}

// assumes pow2 alignment
$align_forward := fn(value: uint, alignment: uint): uint {
	return value + alignment - 1 & ~(alignment - 1)
}

main := fn(): uint {
	niche := find_niche(X)
	if niche == null return 1
	if niche.?.pos != 12 return 2
	if niche.?.size != 4 return 3
	return 0
}
