lily := @use("lib/lib.hb");

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.Vec

printf := fn(str: ^u8, u: uint): void @import()

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
		lily.log.info("pushed to vec\0")
	}

	z := vec.remove(1)
	z = vec.remove(3)
	if z != null {
		// should print `zub zub 4`
		// fails to print anything
		// search "(compiler) bug:" in the whole codebase to find bugs
		// additional bugs tbd
		printf("zub zub %d\n\0".ptr, z)
	}

	return 0
}