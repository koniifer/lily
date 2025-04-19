expectations := .{
	return_value: 0,
}

lily.{TypeOf} := @use("../../src/lib.hb")

main := fn(): uint {
	$match TypeOf(@as(uint, 1)).kind() {
		.Builtin => {
		},
		_ => return 1,
	}
	return 0
}
