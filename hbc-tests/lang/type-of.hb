expectations := .{
	return_value: 0,
}

TypeOf := fn(v: @Any()): type return Generic(@TypeOf(v))
Generic := fn($T: type): type return struct { .inner: T }

main := fn(): uint {
    $if TypeOf(@as(uint, 1)) != Generic(uint) {
        return 1
    }
    return 0
}