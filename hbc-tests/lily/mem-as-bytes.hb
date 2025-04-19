expectations := .{
	return_value: 0,
	emulate_ecalls: true,
}

lily.{mem} := @use("../../src/lib.hb")

A := struct{.a: u8 = 51; .b: u8 = 42; .c: u8 = 77}

main := fn(): uint {
	bytes := mem.as_bytes(&A.{})
	if bytes.len != 3 return 1
	if bytes[0] != 51 return 51
	if bytes[1] != 42 return 42
	if bytes[2] != 77 return 77
	return 0
}
