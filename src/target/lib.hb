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
	exit_group,
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
	.hbvm_ableos;
	.x86_64_linux;
	.unknown;
}

_current := fn(): Target {
	$if @target("hbvm-ableos") return .hbvm_ableos
	$if @target("x86_64-linux") return .x86_64_linux
	@error("unknown target")
}

$current := _current()

lib := fn(): type {
	$match _current() {
		.hbvm_ableos => return @use("hbvm-ableos.hb"),
		.x86_64_linux => return @use("x86_64-linux.hb"),
		_ => @error("unknown target"),
	}
}
