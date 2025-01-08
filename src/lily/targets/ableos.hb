.{LogLevel} := @use("../lib.hb").std.log

$PAGE_SIZE := 4096

LogMsg := packed struct {level: LogLevel, string: ^u8, strlen: uint}

$calculate_pages := fn(size: uint): uint {
	return (size + PAGE_SIZE - 1) / PAGE_SIZE
}

AllocMsg := packed struct {a: u8, count: uint, zeroed: bool}
$malloc := fn(size: uint): ?^void {
	return @eca(3, 2, &AllocMsg.(0, calculate_pages(size), false), @sizeof(AllocMsg))
}

$calloc := fn(size: uint): ?^void {
	return @eca(3, 2, &AllocMsg.(0, calculate_pages(size), true), @sizeof(AllocMsg))
}

ReallocMsg := packed struct {a: u8, count: uint, count_new: uint, ptr: ^void}
$realloc := fn(ptr: ^void, size: uint, size_new: uint): ?^void {
	return @eca(3, 2, &ReallocMsg.(7, calculate_pages(size), calculate_pages(size_new), ptr), @sizeof(ReallocMsg))
}

FreeMsg := packed struct {a: u8, count: uint, ptr: ^void}
$free := fn(ptr: ^void, size: uint): void {
	return @eca(3, 2, &FreeMsg.(1, calculate_pages(size), ptr), @sizeof(FreeMsg))
}

CopyMsg := packed struct {a: u8, count: uint, src: ^void, dest: ^void}
$memcpy := fn(dest: ^void, src: ^void, size: uint): void {
	return @eca(3, 2, &CopyMsg.(4, size, src, dest), @sizeof(CopyMsg))
}

SetMsg := packed struct {a: u8, count: uint, size: uint, src: ^void, dest: ^void}
$memset := fn(dest: ^void, src: u8, size: uint): void {
	return @eca(3, 2, &SetMsg.(5, size, 1, @bitcast(&src), dest), @sizeof(SetMsg))
}

$memmove := fn(dest: ^void, src: ^void, size: uint): void {
	return @eca(3, 2, &CopyMsg.(6, size, src, dest), @sizeof(CopyMsg))
}

$getrandom := fn(dest: ^void, size: uint): void return @eca(3, 4, dest, size)

$exit := fn(code: int): void {
}