lib.{
	LogEcall,
	pages,
	page_len,
	alloc,
	alloc_zeroed,
	realloc,
	dealloc,
	memcopy,
	memmove,
	memset,
	memfill,
	exit,
	fill_rand,
	fork,
} := Lib(current())

Target := enum {
	.AbleOS;
}

current := fn(): Target {
	$if @target("ableos") {
		return .AbleOS
	} else {
		@error("Unknown Target")
	}
}

Lib := fn(target: Target): type {
	$match target {
		.AbleOS => return @use("ableos.hb"),
	}
}
