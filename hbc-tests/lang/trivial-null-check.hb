expectations := .{
	return_value: 0,
}

opaque := fn(): ?^u8 {
	return null
}

$transparent := fn(): ?^u8 {
	return null
}

main := fn(): u8 {
	result := opaque()
	if result != null {
		return 1
	}
	result2 := transparent()
	if result2 != null {
		return 1
	}
	return 0
}
