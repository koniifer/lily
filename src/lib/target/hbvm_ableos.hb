.{log: .{LogLevel}} := @use("../lib.hb")

$PAGE_SIZE := 4096

LogMsg := packed struct {level: LogLevel, string: ^u8, strlen: uint}

$calculate_pages := fn(size: uint): uint {
	return (size + PAGE_SIZE - 1) / PAGE_SIZE
}

RqPageMsg := packed struct {a: u8, count: uint}
$request_pages := fn(count: uint): ?^void {
	return @eca(3, 2, &RqPageMsg.(0, count), @sizeof(RqPageMsg))
}

FreePageMsg := packed struct {a: u8, count: uint, ptr: ^void}
$free_pages := fn(ptr: ^void, count: uint): void {
	return @eca(3, 2, &FreePageMsg.(1, count, ptr), @sizeof(FreePageMsg))
}

$malloc := fn(size: uint): ?^void {
	return request_pages(calculate_pages(size))
}

$free := fn(ptr: ^void, size: uint): void {
	free_pages(ptr, calculate_pages(size))
}

CopyMsg := packed struct {a: u8, count: uint, src: ^void, dest: ^void}
$memcpy := fn(dest: ^void, src: ^void, size: uint): void {
	return @eca(3, 2, &CopyMsg.(4, size, src, dest), @sizeof(CopyMsg))
}

SetMsg := packed struct {a: u8, count: uint, size: uint, src: ^void, dest: ^void}
$memset := fn(dest: ^void, src: u8, size: uint): void {
	return @eca(3, 2, &SetMsg.(5, size, 1, @bitcast(&src), dest), @sizeof(SetMsg))
}

memmove := fn(dest: ^void, src: ^void, size: uint): void {
	memcpy(dest, src, size)
	memset(src, 0, size)
}

$getrandom := fn(dest: ^void, size: uint): void return @eca(3, 4, dest, size)

$exit := fn(code: int): void {
}