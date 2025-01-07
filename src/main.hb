lily := @use("lib/lib.hb");

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.Vec
Random := lily.rand.SimpleRandom
Result := lily.result.Result

main := fn(argc: uint, argv: []^void): uint {
	allocator := Allocator.new()
	defer allocator.deinit()
	vec := Vec(uint, Allocator).new(&allocator)
	defer vec.deinit()
	rand := Random.new()
	defer rand.deinit()

	i := 0
	// ! (compiler) bug: using `if i < 5 {}` rather than `if i >= 5 break else {}` causes
	//		the program to halt after the loop
	// ! (compiler) bug: checking against `vec.len` rather than `i` causes the loop to go forever
	//		despite the fact that vec.len is incremented in vec.push
	loop if i == 5 break else {
		defer i += 1
		vec.push(rand.any(uint))
		lily.log.info("pushed to vec")
	}

	// ! (c_native) this causes a compiler bug in lily.fmt.fmt_int
	// lily.log.print(100)

	lily.log.print(true)

	z := vec.remove(1)
	if z != null {
		lily.log.info("removed from vec")
	}

	// lily.log.info("the following should panic:")
	// a := Result(bool, bool).err(false)
	// // how to make allocator clean up on process exit?
	// _ = a.unwrap()

	return 0
}