.{iter: .{Iterator, IterNext}, Type} := @use("lib.hb")

reverse := fn(str: []u8): void {
	if str.len == 0 return;
	j := str.len - 1
	i := 0
	temp := @as(u8, 0)
	loop if i < j {
		temp = str[i]
		str[i] = str[j]
		str[j] = temp
		i += 1
		j -= 1
	} else return
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

clear := fn(str: []u8): void {
	i := 0
	loop if i == str.len break else {
		str[i] = 0
		i += 1
	}
}

split_once := fn(haystack: []u8, needle: @Any()): ?struct {left: []u8, right: []u8} {
	T := @TypeOf(needle)
	i := 0
	if T == []u8 {
		if needle.len == 0 return null
		loop {
			if i + needle.len > haystack.len return null
			if haystack[i] == needle[0] {
				matches := true
				n := 1
				loop {
					if n == needle.len break
					if haystack[i + n] != needle[n] {
						matches = false
						break
					}
					n += 1
				}

				if matches return .(haystack[0..i], haystack[i + needle.len..])
			}
			i += 1
		}
	} else if T == u8 {
		loop {
			if haystack[i] == needle {
				return .(haystack[0..i], haystack[i + 1..])
			} else if i == haystack.len return null
			i += 1
		}
	} else {
		@error("Type of needle must be []u8 or u8.")
	}
}

split := fn(str: []u8, needle: @Any()): Iterator(struct {
	str: []u8,
	needle: @TypeOf(needle),
	finished: bool = false,

	next := fn(self: ^Self): IterNext([]u8) {
		splits := split_once(self.str, self.needle)
		if self.finished return .(true, Type([]u8).uninit())
		if splits != null {
			self.str = splits.right
			return .(false, splits.left)
		} else {
			self.finished = true
			return .(false, self.str)
		}
	}
}) {
	T := @TypeOf(needle)
	if T != []u8 & T != u8 {
		@error("Type of needle must be []u8 or u8.")
	}
	return .(.{str, needle})
}

chars := fn(iter: []u8): Iterator(struct {
	str: []u8,

	$next := fn(self: ^Self): IterNext(u8) {
		tmp := IterNext(u8).(self.str.len == 0, self.str[0])
		self.str = self.str[1..]
		return tmp
	}
}) {
	return .(.(iter))
}

chars_ref := fn(iter: []u8): Iterator(struct {
	str: []u8,

	$next := fn(self: ^Self): IterNext(^u8) {
		tmp := IterNext(^u8).(self.str.len == 0, self.str.ptr)
		self.str = self.str[1..]
		return tmp
	}
}) {
	return .(.(iter))
}

count := fn(haystack: []u8, needle: @Any()): uint {
	T := @TypeOf(needle)
	i := 0
	c := 0
	if T == []u8 {
		if needle.len == 0 return null
		loop {
			if i + needle.len > haystack.len return c
			if haystack[i] == needle[0] {
				matches := true
				n := 1
				loop {
					if n == needle.len break
					if haystack[i + n] != needle[n] {
						matches = false
						break
					}
					n += 1
				}

				if matches c += 1
			}
			i += 1
		}
	} else if T == u8 {
		loop {
			if haystack[i] == needle c += 1 else if i == haystack.len return c
			i += 1
		}
	} else {
		@error("Type of needle must be []u8 or u8.")
	}
}

left_trim := fn(str: []u8, sub: []u8): []u8 {
	i := 0
	if str[0] == sub[0] {
		loop if i == sub.len {
			return str[i..str.len]
		} else if str[i] != sub[i] | i == str.len {
			break
		} else {
			i += 1
		}
	}
	return str
}

right_trim := fn(str: []u8, sub: []u8): []u8 {
	i := 0
	if str[str.len - 1] == sub[sub.len - 1] {
		loop if i == sub.len {
			return str[0..str.len - i]
		} else if str[str.len - i - 1] != sub[sub.len - i - 1] | i == str.len {
			break
		} else {
			i += 1
		}
	}
	return str
}

trim := fn(str: []u8, sub: []u8): []u8 {
	return right_trim(left_trim(str, sub), sub)
}