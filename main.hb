lily.{fmt, log, mem, alloc, target} := @use("lily")

main := fn(): uint {
	lily.panic(42)
	return 0
}
