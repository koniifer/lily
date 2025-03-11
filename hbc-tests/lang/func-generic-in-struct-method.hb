expectations := .{
    return_value: 0,
}

A := struct {
	apply := fn(self: ^@CurrentScope(), $func: type): uint {
		return func()
    }
}

main := fn(): uint {
	return A.().apply(fn(): uint {
		return 0
	})
}