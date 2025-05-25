.{
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
} := lib()

Target := enum {
	.AbleOS;
	.Unknown;
}

current := fn(): Target {
	$if @target("ableos") {
		return .AbleOS
	}
	@error("unknown target")
}

lib := fn(): type {
	$match current() {
		.AbleOS => return @use("ableos.hb"),
		.Unknown => @error("unknown target"),
	}
}
