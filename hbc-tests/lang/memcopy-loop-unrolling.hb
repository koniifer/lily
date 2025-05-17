expectations := .{
  return_value: 0,
}

$STATIC_COPY_SIZE := 1024

$memcopy := fn(dest: ^u8, src: ^u8, len: uint): void {
    end := src + len
    n := STATIC_COPY_SIZE
    $loop if n == 0 break else {
        loop if src + n > end break else {
            @as(^[n]u8, @bit_cast(dest)).* = @as(^[n]u8, @bit_cast(src)).*
            src += n
            dest += n
        }
        n >>= 1
    }
}

main := fn(): uint {
    arr0 := u8.[1,2,3,4,5]
    arr1: [5]u8 = idk
    memcopy(@bit_cast(&arr0), @bit_cast(&arr1), arr0.len)
    if arr0[0] != arr1[0] return 1
    if arr0[1] != arr1[1] return 1
    if arr0[2] != arr1[2] return 1
    if arr0[3] != arr1[3] return 1
    if arr0[4] != arr1[4] return 1
    return 0
}