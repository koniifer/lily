// ! stub
Vec := fn(T: type, A: type): type return struct {
	.slice: []T;
	.cap: uint;
	.allocator: ^A

	new := fn(allocator: ^A): @CurrentScope() {
		return .(idk, 0, allocator)
	}
}
