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
	rand_fill,
	proc_fork,
	proc_spawn,
	buf_create_named,
	buf_create,
	buf_destroy,
	buf_search,
	buf_await,
	buf_read,
	buf_write,
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
