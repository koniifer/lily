expectations := .{
	return_value: 0,
}

lily.{mem} := @use("../../src/lib.hb")

main := fn(): uint {
	str := "abc||||abcabc"

	if mem.count(str, 'a', false) != 3 return 1
	if mem.count(str, "||", true) != 3 return 2
	if mem.count(str, "||", false) != 2 return 3
	if mem.count(str, "abc", false) != 3 return 4
	if mem.count(str, "abc", true) != 3 return 5

	return 0
}
