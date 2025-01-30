Target := enum {
	LibC,
	AbleOS,

	ableos := @use("ableos.hb")
	libc := @use("libc.hb")

	$current := fn(): Self {
		// This captures all HBVM targets, but for now only AbleOS is supported
		if @target("*-virt-unknown") {
			return .AbleOS
		}
		// Assume that unknown targets have libc
		return .LibC
	}
	$Lib := fn(self: Self): type {
		match self {
			.AbleOS => return Self.ableos,
			.LibC => return Self.libc,
		}
	}
	/* ! memmove, memcpy, memset, exit, currently suffixed with `_w` to distinguish them from the wrapper functions */;
	/* todo: reorganise these */;
	.{alloc, alloc_zeroed, realloc, dealloc, memmove: memmove_w, memcpy: memcpy_w, memset: memset_w, exit: exit_w, getrandom, page_size, calculate_pages, fork} := Self.Lib(Self.current());
	.{printf_str} := Self.Lib(.LibC);
	.{LogMsg} := Self.Lib(.AbleOS)
}