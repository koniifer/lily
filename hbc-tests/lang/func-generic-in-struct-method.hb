expectations := .{
    return_value: 0,
}

A := struct {
	apply := fn(self: ^@CurrentScope(), $func: type): void {
    }
}

main := fn(): void {
	return A.().apply(fn(): void {
	})
}