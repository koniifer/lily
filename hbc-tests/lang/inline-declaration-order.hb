expectations := .{
	return_value: 0,
}

secondary := fn(): uint {
    return inlined()
}

// ! if $ is removed this works.
// ! if this function is moved above `secondary`, this works.
$inlined := fn(): uint {
    return 0
}

main := fn(): uint {
    return secondary()
}