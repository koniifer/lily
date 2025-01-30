.{LogLevel} := @use("../lib.hb").log

$page_size := fn(): uint {
	return 4096
}

LogMsg := packed struct {level: LogLevel, string: ^u8, strlen: uint}

$calculate_pages := fn(size: uint): uint {
	return (size + page_size() - 1) / page_size()
}

AllocMsg := packed struct {a: u8, count: uint, zeroed: bool}
$alloc := fn(size: uint): ?^u8 {
	return @eca(3, 2, &AllocMsg.(0, calculate_pages(size), false), @sizeof(AllocMsg))
}

$alloc_zeroed := fn(size: uint): ?^u8 {
	return @eca(3, 2, &AllocMsg.(0, calculate_pages(size), true), @sizeof(AllocMsg))
}

ReallocMsg := packed struct {a: u8, count: uint, count_new: uint, ptr: ^u8}
$realloc := fn(ptr: ^u8, size: uint, size_new: uint): ?^u8 {
	return @eca(3, 2, &ReallocMsg.(7, calculate_pages(size), calculate_pages(size_new), ptr), @sizeof(ReallocMsg))
}

FreeMsg := packed struct {a: u8, count: uint, ptr: ^u8}
$dealloc := fn(ptr: ^u8, size: uint): void {
	return @eca(3, 2, &FreeMsg.(1, calculate_pages(size), ptr), @sizeof(FreeMsg))
}

CopyMsg := packed struct {a: u8, count: uint, src: ^u8, dest: ^u8}
$memcpy := fn(dest: ^u8, src: ^u8, size: uint): void {
	return @eca(3, 2, &CopyMsg.(4, size, src, dest), @sizeof(CopyMsg))
}

SetMsg := packed struct {a: u8, count: uint, size: uint, src: ^u8, dest: ^u8}
$memset := fn(dest: ^u8, src: u8, size: uint): void {
	return @eca(3, 2, &SetMsg.(5, size, 1, @bitcast(&src), dest), @sizeof(SetMsg))
}

$memmove := fn(dest: ^u8, src: ^u8, size: uint): void {
	return @eca(3, 2, &CopyMsg.(6, size, src, dest), @sizeof(CopyMsg))
}

$getrandom := fn(dest: ^u8, size: uint): void return @eca(3, 4, dest, size)

$exit := fn(code: int): void {
}

$fork := fn(): uint return @eca(3, 7)