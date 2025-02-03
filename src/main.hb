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
// inlining this breaks it :(
$add := fn(sum: uint, x: uint): uint {
	return sum + x
}

main := fn(argc: uint, argv: []^void): uint {
	sum := Generator.{}.into_iter().take(50).fold(add, 0)
	lily.print(sum)

	// // ! (libc) (compiler) bug: .collect(T) does not work.
	// if lily.Target.current() != .LibC {
	// 	str := lily.string.chars("Hello, ").intersperse(
	// 		lily.string.chars("World!"),
	// 	).collect([13]u8)

	// 	if str != null {
	// 		lily.log.info(@as([13]u8, str)[..])
	// 	} else {
	// 		lily.panic("could not collect (array wrong size)")
	// 	}
	// } else {
	// 	// yes, im cheating if you are on libc.
	// 	// it's not my fault, blame compiler bugs. T^T
	// 	lily.log.info("HWeolrllod,! ")
	// }

	// return 0

	/* ! the following will ONLY work on ableos
	 * due to fun compiler bugs
	 */
	// allocator := lily.alloc.SimpleAllocator.new()
	// defer allocator.deinit()
	// map := lily.collections.HashMap(
	// 	uint,
	// 	uint,
	// 	lily.hash.FoldHasher,
	// 	lily.alloc.SimpleAllocator,
	// ).new(&allocator)
	// defer map.deinit()

	// i := 0
	// $loop if i == 99 * 2 break else {
	// 	_ = map.insert(i, 0)
	// 	_ = map.insert(i + 1, 0)
	// 	i += 2
	// }
	// map.keys().for_each(lily.print)

	// fun thing
	// _ = map.insert("Farewell, World!", "beep boop")
	// _ = map.insert("Hello, World!", "Hello!")
	// _ = map.insert("Goodbye, World!", "Goodbye!")
	// _ = map.insert("How do you do, World?", "Great!")
	// _ = map.insert("Until next time, World!", "See you!")
	// _ = map.insert("Greetings, World!", "Hi there!")

	// lily.print(map.get("asdfasdf!"))
	// lily.print(map.get("Hello, World!"))

	// id := lily.process.fork()
	// lily.print("hello, world")

	// if id == 0 {
	// 	lily.print("child")
	// } else {
	// 	lily.print("parent")
	// }

	// Allocator := lily.alloc.ArenaAllocator
	// allocator := Allocator.new()
	// defer allocator.deinit()
	// vec := lily.collections.Vec(uint, Allocator).new(&allocator)
	// i := 0
	// // ! (skill issue) bug: i > 512 causes SIGSEGV
	// loop if i == 1024 break else {
	// 	defer i += 1
	// 	vec.push(i)
	// }
	// lily.print(vec.slice.len)

	return 0
}