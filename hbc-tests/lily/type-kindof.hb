expectations := .{
	return_value: 0,
}

lily.{Type} := @use("../../src/lib.hb")

main := fn(): uint {
	// ! (compiler) bug: "the functions types most likely depend on it being evaluated"
	$match Type(uint).kind() {
		.Builtin => {
		},
		_ => return 1,
	}
	return 0
}
