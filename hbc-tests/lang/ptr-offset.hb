expectations := .{
    return_value: 0,
}

main := fn(): uint {
    ptr0: ^u8 = @bit_cast(0)
    ptr1 := ptr0 + 100
    if ptr0 != @bit_cast(100) return 1
    return 0
}