expectations := .{
	return_value: 0,
}

lily.{Type} := @use("../../src/lib.hb")

main := fn(): uint {
	$match Type([10]uint).kind() {
		.Array => {
		},
		_ => return 1,
	}
	$match Type(main).kind() {
		.Function => {
		},
		_ => return 2,
	}
	$match Type(uint).kind() {
		.Builtin => {
		},
		_ => return 3,
	}
	$match Type([]u8).kind() {
		.Slice => {
		},
		_ => return 3,
	}
	return 0
}
