lily.{target, log, mem} := @use("lily")

main := fn(): void {
	a := "Hello, World!"
	b := mem.bytes(a).take(5).for_each(fn(x: u8): void {
		if x % 2 == 0 log.info("even") else log.info("odd")
	})
}
