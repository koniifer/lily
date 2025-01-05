lily := @use("lib/lib.hb");

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.SparseVec
Random := lily.rand.SimpleRandom
Result := lily.result.Result

// ! (runtime) bug: leaking memory (waiting on compiler bugfixes)
// ! can't run on target_hbvm_ableos due to unresolved compiler bugs
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

	// ! (c_native) (compiler) bug: compiler panic from vec.remove()
	// z := vec.remove(1)
	// lily.log.info("removed from vec")
	// z = vec.remove(3)
	// lily.log.info("removed from vec")
	// if z != null {
	// ! (compiler) bug: this never happens (even though it should)
	// lily.log.info("zub zub")
	// }

	lily.log.info("the following should panic:")
	a := Result(bool, bool).err(false)
	_ = a.unwrap()

	return 0
}