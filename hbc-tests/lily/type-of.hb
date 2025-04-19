expectations := .{
	return_value: 0,
}

lily.{TypeOf} := @use("../../src/lib.hb")

dependent := fn(v: @Any()): uint {
  $T := TypeOf(v)
  $match T.kind() {
    .Builtin => return 0,
    _ => return 1
  }
}

main := fn(): uint {
	return dependent(@as(uint, 100))
}
