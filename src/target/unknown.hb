$page_len := fn(): uint {
	@error("target ", @CurrentScope(), " does not support memory allocation.")
}
$pages := fn(len: uint): uint {
	@error("target ", @CurrentScope(), " does not support memory allocation.")
}

$alloc := fn(len: uint): ?^u8 {
	@error("target ", @CurrentScope(), " does not support memory allocation.")
}
$alloc_zeroed := fn(len: uint): ?^u8 {
	@error("target ", @CurrentScope(), " does not support memory allocation.")
}

$realloc := fn(ptr_old: ^u8, len_old: uint, len_new: uint): ?^u8 {
	@error("target ", @CurrentScope(), " does not support memory allocation.")
}

$dealloc := fn(ptr: ^u8, len: uint): void {
	@error("target ", @CurrentScope(), " does not support memory allocation.")
}

$STATIC_COPY_SIZE := 1024

// safety: assumes alignment and nonoverlapping regions. assumes len != 0
$memcopy := fn(dest: ^u8, src: ^u8, len: uint): void {
	end := src + len
	n := STATIC_COPY_SIZE
	$loop $if n == 0 break else {
		loop if src + n > end break else {
			@as(^[n]u8, @bit_cast(dest)).* = @as(^[n]u8, @bit_cast(src)).*
			src += n
			dest += n
		}
		n >>= 1
	}
}
$memmove := fn(dest: ^u8, src: ^u8, len: uint): void {
	@error("todo: ", memmove)
}

// safety: assumes len != 0
$memset := fn(dest: ^u8, src: u8, len: uint): void {
	@error("todo: ", memset)
}
$memfill := fn(dest: ^u8, src: ^u8, count: uint, len: uint): void {
	@error("todo: ", memfill)
}

$exit := fn(code: u8): void {
	@error("target ", @CurrentScope(), " does not support early exit.")
}

$rand_fill := fn(dest: ^u8, len: uint): void {
	@error("target ", @CurrentScope(), " does not support os random.")
}

$proc_fork := fn(): uint {
	@error("target ", @CurrentScope(), " does not support process forking.")
}
$proc_spawn := fn(executable: []u8): uint {
	@error("target ", @CurrentScope(), " does not support process spawning.")
}

$dt_get := fn($T: type, query: []u8): T {
	@error("target ", @CurrentScope(), " does not support ableos device tree. (duh)")
}

$buf_create_named := fn(name: []u8): uint {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
$buf_create := fn(): uint {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
$buf_destroy := fn(id: uint): void {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
$buf_search := fn(name: []u8): uint {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
$buf_await := fn(id: uint): void {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
$buf_read := fn(id: uint, mmap: []u8): void {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
$buf_write := fn(id: uint, mmap: []u8): void {
	@error("target ", @CurrentScope(), " does not support ipc buffers.")
}
