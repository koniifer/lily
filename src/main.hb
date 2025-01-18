lily := @use("lily/lib.hb");

Generator := struct {
	n: uint = 0,
	$next := fn(self: ^Self): lily.iter.IterNext(uint) {
		self.n += 1
		return .(false, self.n)
	}
	$into_iter := fn(self: Self): lily.iter.Iterator(Self) {
		return .(self)
	}
}

$add := fn(sum: uint, x: uint): uint {
	return sum + x
}

main := fn(argc: uint, argv: []^void): uint {
	sum := Generator.{}.into_iter().take(50).fold(add, 0)
	lily.print(sum)

	// ! (libc) (compiler) bug: .collect(T) does not work.
	if lily.Target.current() != .LibC {
		str := lily.string.chars("Hello, ").intersperse(
			lily.string.chars("World!"),
		).collect([13]u8)

		if str != null {
			lily.log.info(@as([13]u8, str)[..])
		} else {
			lily.panic("could not collect (array wrong size)")
		}
	} else {
		lily.log.info("HWeolrllod,! ")
	}

	return 0
}