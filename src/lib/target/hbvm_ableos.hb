$PAGE_SIZE := 4096
$MAX_ALLOC := 0xFF
$MAX_FREE := 0xFF

$calculate_pages := fn(size: uint): uint {
	return (size + PAGE_SIZE - 1) / PAGE_SIZE
}

RqPageMsg := packed struct {a: u8, count: u8}
$request_pages := fn(count: u8): ?^void {
	return @eca(3, 2, &RqPageMsg.(0, count), @sizeof(RqPageMsg))
}

FreePageMsg := packed struct {a: u8, count: u8, ptr: ^void}
$free_pages := fn(ptr: ^void, count: u8): void {
	return @eca(3, 2, &FreePageMsg.(1, count, ptr), @sizeof(FreePageMsg))
}

malloc := fn(size: uint): ?^void {
	pages := calculate_pages(size)
	if pages <= MAX_ALLOC {
		return @bitcast(request_pages(@intcast(pages)))
	}
	ptr := request_pages(MAX_ALLOC)
	if ptr == null return null
	pages -= MAX_ALLOC
	loop if pages <= MAX_ALLOC break else {
		if request_pages(MAX_ALLOC) == null return null
		pages -= MAX_ALLOC
	}
	if request_pages(@intcast(pages)) == null return null
	return @bitcast(ptr)
}

free := fn(ptr: ^void, size: uint): void {
	pages := calculate_pages(size)
	if pages <= MAX_FREE {
		return free_pages(ptr, @intcast(pages))
	}
	loop if pages <= MAX_FREE break else {
		free_pages(ptr, MAX_FREE)
		ptr += PAGE_SIZE * MAX_FREE
		pages -= MAX_FREE
	}
	free_pages(ptr, @intcast(pages))
}

CopyMsg := packed struct {a: u8, count: uint, src: ^void, dest: ^void}
$memcopy := fn(dest: ^void, src: ^void, size: uint): void {
	return @eca(3, 2, &CopyMsg.(4, size, src, dest), @sizeof(CopyMsg))
}

SetMsg := packed struct {a: u8, count: uint, size: uint, src: ^void, dest: ^void}
$memset := fn(dest: ^void, src: ^void, size: uint): void {
	return @eca(3, 2, &SetMsg.(5, size, 1, src, dest), @sizeof(SetMsg))
}

memmove := fn(dest: ^void, src: ^void, size: uint): void {
	memcopy(dest, src, size)
	memset(src, @bitcast(&0), size)
}

$exit := fn(code: int): void {
}