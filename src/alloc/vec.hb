// ! stub
Vec := fn(T: type, A: type): type return struct {
	.slice: []T;
	.cap: uint;
	.allocator: ^A

	Self := @CurrentScope()

	$new := fn(allocator: ^A): Self {
		return .(idk, 0, allocator)
	}

	deinit := fn(self: ^Self): void {
	}
}
