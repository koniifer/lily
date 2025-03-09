expectations := .{
    return_value: 0,
}

// ! (compiler) bug: parser has no clue what to do with this
// ! additionally, if $a: @Any(), then 'type can not be constructed as integer literal' referring to 'a'
func := fn(a: @Any(), b: @TypeOf(a)): uint {
    return 0
}

main := fn(): uint {
    return func(@as(uint, 1), 2)
}