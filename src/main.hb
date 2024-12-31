std := @use("lib/lib.hb");

Allocator := std.alloc.SimpleAllocator
Vec := std.collections.Vec

main := fn(argc: uint, argv: []^u8): uint {
	allocator := Allocator.new()
	defer allocator.deinit()
	vec := Vec(int, Allocator).new(&allocator)
	defer vec.deinit()

	i: int = 0
	loop if i == 97 break else {
		defer i += 1
		vec.push(i)
	}
	// ! (compiler?) (target_c_native?) bug: not popping here causes len & cap to be zero
	_ = vec.pop()
	return vec.len()
}