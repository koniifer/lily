/*
 * exit: 0
 */
RawKind := enum {
	Builtin,
	Struct,
	Tuple,
	Enum,
	Union,
	Pointer,
	Slice,
	Optional,
	Function,
	Template,
	Global,
	Constant,
	Module,
}

Kind := enum {
	Builtin,
	Struct,
	Tuple,
	Enum,
	Union,
	Pointer,
	Slice,
	Array,
	Optional,
	Function,
	Template,
	Global,
	Constant,
	Module,
}
Type := fn($T: type): type return struct {
	Child := fn(): type {
		return Type(@ChildOf(T))
	}
	This := fn(): type {
		return T
	}
	$raw_kind := fn(): RawKind {
		return @bitcast(@kindof(T))
	}
	$kind := fn(): Kind {
		if Self.raw_kind() == .Slice {
			if []@ChildOf(T) == T return .Slice else return .Array
		} else if @kindof(T) > @bitcast(Kind.Slice) {
			return @bitcast(@kindof(T) + 1)
		} else return @bitcast(Self.raw_kind())
	}
	/// ! There are no guarantees that this value is zeroed for builtins, enums, unions, structs, arrays, or tuples.
	$uninit := fn(): T {
		match Self.kind() {
			.Pointer => return @bitcast(0),
			.Slice => return Type(^Self.Child().This()).uninit()[0..0],
			_ => @error("Type(", T, ").uninit() does not make sense."),
		}
	}
}
Vec := struct {
	slice: []u8,
	$new := fn(): Self return .{slice: Type([]u8).uninit()}
	push := fn(self: ^Self, value: u8): void {
		self.slice[self.slice.len] = value
	}
}
main := fn(): u8 {
	foo := Vec.new()
	foo.push(6)
	return 0
}
