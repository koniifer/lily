.{LogLevel} := @use("../lib.hb").log

LogEcall := struct align(1){.level: LogLevel; .str_ptr: ^u8; .str_len: uint}

$page_len := fn(): uint return 4096
$pages := fn(len: uint): uint return (len + page_len() - 1) / page_len()

AllocEcall := struct align(1){.pad: u8; .pages_new: uint; .zeroed: bool}
$alloc := fn(len: uint): ?^u8 {
	return @ecall(3, 2, AllocEcall.(0, pages(len), false), @size_of(AllocEcall))
}
$alloc_zeroed := fn(len: uint): ?^u8 {
	return @ecall(3, 2, AllocEcall.(0, pages(len), true), @size_of(AllocEcall))
}

ReallocEcall := struct align(1){.pad: u8; .pages_old: uint; .pages_new: uint; .ptr_old: ^u8}
$realloc := fn(ptr_old: ^u8, len_old: uint, len_new: uint): ?^u8 {
	return @ecall(3, 2, ReallocEcall.(7, pages(len_old), pages(len_new), ptr_old), @size_of(ReallocEcall))
}

DeallocEcall := struct align(1){.pad: u8; .pages: uint; .ptr: ^u8}
$dealloc := fn(ptr: ^u8, len: uint): void {
	@ecall(3, 2, DeallocEcall.(1, pages(len), ptr), @size_of(DeallocEcall))
}

CopyEcall := struct align(1){.pad: u8; .len: uint; .src: ^u8; .dest: ^u8}
$memcopy := fn(dest: ^u8, src: ^u8, len: uint): void {
	@ecall(3, 2, CopyEcall.(4, len, src, dest), @size_of(CopyEcall))
}
$memmove := fn(dest: ^u8, src: ^u8, len: uint): void {
	@ecall(3, 2, CopyEcall.(6, len, src, dest), @size_of(CopyEcall))
}

FillEcall := struct align(1){.pad: u8; .count: uint; .len: uint; .src: ^u8; .dest: ^u8}
$memset := fn(dest: ^u8, src: u8, len: uint): void {
	@ecall(3, 2, FillEcall.(5, len, 1, &src, dest), @size_of(FillEcall))
}
$memfill := fn(dest: ^u8, src: ^u8, count: uint, len: uint): void {
	@ecall(3, 2, FillEcall.(5, count, len, src, dest), @size_of(FillEcall))
}

$exit := fn(code: uint): never die
$exit_group := fn(code: uint): never die

$rand_fill := fn(dest: ^u8, len: uint): void return @ecall(3, 4, dest, len)

$proc_fork := fn(): uint return @ecall(3, 7)
$proc_spawn := fn(executable: []u8): uint {
	return @ecall(3, 6, executable.ptr, executable.len)
}

$dt_get := fn($T: type, query: []u8): T {
	return @ecall(3, 5, query.ptr, query.len)
}

BufferEcall := struct align(1){.operation: u8; .str_ptr: ^u8; .str_len: uint}
$buf_create_named := fn(name: []u8): uint {
	return @ecall(3, 0, BufferEcall.(0, name.ptr, name.len), @size_of(BufferEcall))
}
$buf_create := fn(): uint {
	return @ecall(1, 0)
}
$buf_destroy := fn(id: uint): void {
	return @ecall(2, id)
}
$buf_search := fn(name: []u8): uint {
	return @ecall(3, 0, BufferEcall.(3, name.ptr, name.len), @size_of(BufferEcall))
}
$buf_await := fn(id: uint): void {
	return @ecall(7, id)
}
$buf_read := fn(id: uint, mmap: []u8): void {
	return @ecall(4, id, mmap.ptr, mmap.len)
}
$buf_write := fn(id: uint, mmap: []u8): void {
	return @ecall(3, id, mmap.ptr, mmap.len)
}
