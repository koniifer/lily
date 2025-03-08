.{LogLevel} := @use("../lib.hb").log

LogEcall := struct align(1){.level: LogLevel; .str_ptr: ^u8; .str_len: uint}

$page_len := fn(): uint {
	return 4096
}

$pages := fn(len: uint): uint {
	return (len + page_len() - 1) / page_len()
}

AllocEcall := struct align(1){.pad: u8; .pages_new: uint; .zeroed: bool}
// todo: return ?^u8
$alloc := fn(len: uint): ^u8 {
	return @ecall(3, 2, AllocEcall.(0, pages(len), false), @size_of(AllocEcall))
}

// todo: return ?^u8
$alloc_zeroed := fn(len: uint): ^u8 {
	return @ecall(3, 2, AllocEcall.(0, pages(len), true), @size_of(AllocEcall))
}

ReallocEcall := struct align(1){.pad: u8; .pages_old: uint; .pages_new: uint; .ptr_old: ^u8}
// todo: return ?^u8.
$realloc := fn(ptr_old: ^u8, len_old: uint, len_new: uint): ^u8 {
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

SetEcall := struct align(1){.pad: u8; .count: uint; .len: uint; .src: ^u8; .dest: ^u8}
$memset := fn(dest: ^u8, src: u8, len: uint): void {
	@ecall(3, 2, SetEcall.(5, len, 1, &src, dest), @size_of(SetEcall))
}

$exit := fn(code: u8): void {
}
$fill_rand := fn(dest: ^u8, len: uint): void return @ecall(3, 4, dest, len)
$fork := fn(): uint return @ecall(3, 7)
