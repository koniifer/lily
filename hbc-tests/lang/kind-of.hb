expectations := .{
	return_value: 0,
}

Kind := enum {
	.Builtin;
	.Pointer;
}

kind := fn($T: type): Kind {
	return @bit_cast(@kind_of(T))
}

main := fn(): uint {
	$match kind(uint) {
		.Builtin => return 0,
		_ => return 1,
	}
}
