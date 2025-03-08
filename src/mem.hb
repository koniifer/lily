.{target, iter: .{Iterator, Next}} := @use("lib.hb")

$copy := fn(dest: ^u8, src: ^u8, len: uint): void {
	target.memcopy(dest, src, len)
}

$move := fn(dest: ^u8, src: ^u8, len: uint): void {
	target.memmove(dest, src, len)
}

$set := fn(dest: ^u8, src: u8, len: uint): void {
	target.memset(dest, src, len)
}

equals := fn(lhs: []u8, rhs: []u8): bool {
	if lhs.len != rhs.len return false
	if lhs.ptr == rhs.ptr return true
	i := 0
	loop if i == lhs.len break else {
		if lhs[i] != rhs[i] return false
		i += 1
	}
	return true
}

$bytes := fn(slice: []u8): Iterator(struct {
	.slice: []u8

	$next := fn(self: ^@CurrentScope()): Next(u8) {
		tmp := Next(u8).(self.slice.len == 0, self.slice.ptr.*)
		self.slice = self.slice[1..]
		return tmp
	}
}) {
	return .(.(slice))
}
