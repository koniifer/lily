expectations := .{
	return_value: 0,
}

secondary := fn(): uint {
	return inlined()
}

$inlined := fn(): uint {
	return 0
}

main := fn(): uint {
	return secondary()
}
