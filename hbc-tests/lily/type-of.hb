expectations := .{
    return_value: 0,
}

lily.{TypeOf} := @use("../../src/lib.hb")

main := fn(): uint {
    // ! (compiler) bug: "the functions types most likely depend on it being evaluated"
    $match TypeOf(@as(uint, 1)).kind() {
        .Builtin => {},
        _ => return 1,
    }
    return 0
}