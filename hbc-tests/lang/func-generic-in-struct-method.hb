expectations := .{
    return_value: 0,
}

A := struct {
	apply := fn(self: ^@CurrentScope(), $func: type): void {
        return 0
    }
}

main := fn(): void {
	return A.().apply(fn(): void {
	})
}