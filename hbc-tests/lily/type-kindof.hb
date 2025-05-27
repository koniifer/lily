expectations := .{
	return_value: 0,
}

lily.{TypeInfo} := @use("../../src/lib.hb")

main := fn(): uint {
	$match TypeInfo([10]uint).kind {
		.Array => {
		},
		_ => return 1,
	}
	$match TypeInfo(main).kind {
		.Function => {
		},
		_ => return 2,
	}
	$match TypeInfo(uint).kind {
		.Builtin => {
		},
		_ => return 3,
	}
	$match TypeInfo([]u8).kind {
		.Slice => {
		},
		_ => return 3,
	}
	return 0
}
