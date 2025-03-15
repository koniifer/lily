expectations := .{
	return_value: 0,
}

lily.{fmt} := @use("../../src/lib.hb")

scratch: [4096]u8 = idk

main := fn(): uint {
	len := fmt.fmt_int(scratch[..], 4096, 10)
	if len != 4 return 1
	if scratch[0] != '4' | scratch[1] != '0' | scratch[2] != '9' | scratch[3] != '6' return 1

	len = fmt.fmt_int(scratch[..], 5050, 16)
	if len != 6 return 1
	if scratch[0] != '0' | scratch[1] != 'x' | scratch[2] != '1' | scratch[3] != '3' | scratch[4] != 'B' | scratch[5] != 'A' return 1
	return 0
}
