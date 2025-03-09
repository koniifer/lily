expectations := .{
    return_value: 0,
}

func := fn(a: @Any(), b: @TypeOf(a)): uint {
    return 0
}

main := fn(): uint {
    return func(@as(uint, 1), 2)
}