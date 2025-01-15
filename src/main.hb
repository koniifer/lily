lily := @use("lily/lib.hb")

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.Vec
HashMap := lily.collections.HashMap
Random := lily.rand.SimpleRandom
Result := lily.result.Result
Hasher := lily.hash.FoldHasher

// ! HashMap only works on AbleOS target (due to compiler bugs)

$some_sorter := fn(lhs: @Any(), rhs: @Any()): bool {
	return lhs < rhs
}

$add_one := fn(x: ?uint): ?uint {
	return @unwrap(x) + 1
}

$print := fn(next: @Any()): void {
	lily.print(@as(@ChildOf(@TypeOf(next)), @unwrap(next)))
}

main := fn(): uint {
	allocator := Allocator.new()
	defer allocator.deinit()
	vec := Vec(uint, Allocator).new(&allocator)
	defer vec.deinit()
	rand := Random.default()
	defer rand.deinit()

	i := 0
	loop if i == 100 break else {
		defer i += 1
		vec.push(rand.any(u8))
	}
	// note: this does not affect the values of the vec itself
	// the `add_one` here simply changes the value before printing.
	// ! (libc) (compiler) bug: prints same numbers several times on libc. does not occur on ableos.
	vec.into_iter().map(add_one).for_each(print)

	// equivalent to vec.sort() when some_sorter == `lhs < rhs`
	// uses lily.quicksort under the hood
	vec.sort_with(some_sorter)

	return 0
}