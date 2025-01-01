lily := @use("lib/lib.hb");

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.Vec

// ! (runtime) (target_hbvm_ableos?) bug: leaking memory (1 page in this function)
main := fn(argc: uint, argv: []^void): uint {
	allocator := Allocator.new()
	defer allocator.deinit()
	vec := Vec(uint, Allocator).new(&allocator)
	defer vec.deinit()

	i := 0
	loop if i == 5 break else {
		defer i += 1
		vec.push(i)
		lily.log.print("pushed to vec\0")
	}

	return 0
}