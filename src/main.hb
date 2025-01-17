lily := @use("lily/lib.hb")

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.Vec
HashMap := lily.collections.HashMap
Random := lily.rand.SimpleRandom
Result := lily.result.Result
Hasher := lily.hash.FoldHasher

$ref_char_to_str := fn(char: ^u8): []u8 {
	return char[0..1]
}

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

$add := fn(lhs: uint, rhs: uint): uint {
	return lhs + rhs
}

chars_ref := lily.string.chars_ref

main := fn(argc: uint, argv: []^void): uint {
	a := Generator.{}.into_iter().take(50).fold(add, 0)
	lily.print(a)

	b := chars_ref("Hello,_").chain(chars_ref("World!")).map(ref_char_to_str).for_each(lily.log.info)
	c := chars_ref("Hello,_").intersperse(chars_ref("World!")).map(ref_char_to_str).for_each(lily.log.info)

	// allocator := Allocator.new()
	// defer allocator.deinit()
	// // ! HashMap only works on AbleOS target (due to compiler bugs)
	// map := HashMap(uint, uint, Hasher, Allocator).new(&allocator)
	// defer map.deinit()

	// _ = map.insert(101, 20)
	// _ = map.insert(202, 30)
	// _ = map.insert(303, 40)

	// // ! This iterator only works on AbleOS target (due to compiler bugs)
	// map.items().enumerate().for_each(print)

	return 0
}

// $print := fn(thing: @Any()): void {
// 	.{n, val: item} := thing
// 	// ! printf ALSO only works on AbleOS target (due to compiler bugs)
// 	lily.printf("nth: {}, key: {}, value: {}", .(n, item.key, item.value))
// }