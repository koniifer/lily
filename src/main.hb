std := @use("lib/lib.hb");

Allocator := std.alloc.SimpleAllocator
Vec := std.collections.Vec

main := fn(argc: uint, argv: []^u8): uint {
	allocator := Allocator.new()
	// ! (compiler?) (target_hbvm_ableos) bug: defer deinit on allocator causes kernel panic
	defer allocator.deinit()
	vec := Vec(int, Allocator).new(&allocator)
	defer vec.deinit()

	i: int = 0
	loop if i == 10 break else {
		defer i += 1
		vec.push(i)
	}
	// ! (compiler?) (target_c_native?) bug: not popping here causes len & cap to be zero
	vec.push(vec.pop().unwrap_or(0))
	return vec.len()
}